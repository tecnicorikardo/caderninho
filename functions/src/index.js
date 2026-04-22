const admin = require('firebase-admin')
const { onDocumentCreated } = require('firebase-functions/v2/firestore')
const { onSchedule } = require('firebase-functions/v2/scheduler')
const { onCall, HttpsError } = require('firebase-functions/v2/https')
const { onRequest } = require('firebase-functions/v2/https')
const { logger } = require('firebase-functions')
const { MercadoPagoConfig, Preference, Payment } = require('mercadopago')

admin.initializeApp()

const db = admin.firestore()
const messaging = admin.messaging()
const TOKEN_COLLECTIONS = ['device_tokens', 'fcm_tokens']

function uniq(items) {
  return Array.from(new Set(items.filter(Boolean)))
}

function chunk(items, size = 500) {
  const chunks = []
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size))
  }
  return chunks
}

function asDate(value) {
  if (!value) return null
  if (value instanceof Date) return value
  if (typeof value.toDate === 'function') return value.toDate()
  return null
}

function ymdInTimeZone(date, timeZone = 'America/Sao_Paulo') {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
  })
    .formatToParts(date)
    .reduce((acc, item) => {
      if (item.type === 'year' || item.type === 'month' || item.type === 'day') {
        acc[item.type] = Number(item.value)
      }
      return acc
    }, {})
  return {
    year: parts.year,
    month: parts.month,
    day: parts.day,
    key: `${parts.year}-${String(parts.month).padStart(2, '0')}-${String(parts.day).padStart(2, '0')}`
  }
}

function daysInMonth(year, month) {
  return new Date(Date.UTC(year, month, 0)).getUTCDate()
}

function monthlyDueDay(baseDate, year, month, timeZone = 'America/Sao_Paulo') {
  const baseDay = ymdInTimeZone(baseDate, timeZone).day
  const max = daysInMonth(year, month)
  return Math.min(baseDay, max)
}

function shouldRemindPersonalEntryToday(entryData, today, timeZone) {
  if (entryData.remindersEnabled !== true) return false
  const expectedDate = asDate(entryData.expectedDate || entryData.createdAt)
  if (!expectedDate) return false

  const lastReminder = asDate(entryData.lastReminderAt)
  if (lastReminder && ymdInTimeZone(lastReminder, timeZone).key === today.key) {
    return false
  }

  const recurrence = String(entryData.recurrence || 'once')
  if (recurrence === 'monthly') {
    const day = monthlyDueDay(expectedDate, today.year, today.month, timeZone)
    return today.day === day
  }

  return ymdInTimeZone(expectedDate, timeZone).key === today.key
}

function money(value) {
  return Number(value || 0).toFixed(2).replace('.', ',')
}
async function getUserTokenDocs(userRef, { storeId = null } = {}) {
  const snapshots = await Promise.all(
    TOKEN_COLLECTIONS.map((collectionName) => userRef.collection(collectionName).get())
  )
  const refsByToken = new Map()
  for (const snap of snapshots) {
    for (const doc of snap.docs) {
      const data = doc.data() || {}
      const token = String(data.token || '').trim()
      if (!token) continue
      if (storeId && data.storeId && data.storeId !== storeId) continue
      if (!refsByToken.has(token)) {
        refsByToken.set(token, [])
      }
      refsByToken.get(token).push(doc.ref)
    }
  }
  return Array.from(refsByToken.entries()).map(([token, refs]) => ({ token, refs }))
}

exports.sendPersonalEntryRemindersDaily = onSchedule(
  {
    schedule: 'every day 08:00',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1'
  },
  async () => {
    const timeZone = 'America/Sao_Paulo'
    const now = new Date()
    const today = ymdInTimeZone(now, timeZone)

    try {
      const entriesSnap = await db
        .collectionGroup('personal_entries')
        .where('remindersEnabled', '==', true)
        .get()

      if (entriesSnap.empty) {
        logger.info('Sem personal_entries com lembrete ativo.')
        return
      }

      const perUser = new Map()
      for (const doc of entriesSnap.docs) {
        const userRef = doc.ref.parent.parent
        if (!userRef) continue
        const uid = userRef.id
        if (!perUser.has(uid)) {
          perUser.set(uid, { userRef, entries: [] })
        }
        perUser.get(uid).entries.push(doc)
      }

      let usersNotified = 0
      let notificationsSent = 0

      for (const [uid, payload] of perUser.entries()) {
        const dueDocs = payload.entries.filter((doc) =>
          shouldRemindPersonalEntryToday(doc.data() || {}, today, timeZone)
        )
        if (!dueDocs.length) continue

        const tokenDocs = await getUserTokenDocs(payload.userRef)
        if (!tokenDocs.length) continue

        const revenueCount = dueDocs.filter(
          (doc) => String(doc.data()?.type || '') === 'revenue'
        ).length
        const expenseCount = dueDocs.length - revenueCount
        const totalAmount = dueDocs.reduce(
          (acc, doc) => acc + Number(doc.data()?.amount || 0),
          0
        )
        const first = dueDocs[0].data() || {}
        const firstDesc = String(first.description || 'Lancamento')

        const title = 'Lembrete de gestao pessoal'
        const body =
          dueDocs.length === 1
            ? `${firstDesc}: R$ ${money(first.amount)} previsto para hoje.`
            : `${dueDocs.length} lancamentos hoje (${revenueCount} receita(s), ${expenseCount} despesa(s)) | Total: R$ ${money(totalAmount)}`

        const invalid = new Set()
        let hasSuccess = false

        for (const tokens of chunk(tokenDocs.map((item) => item.token), 500)) {
          const response = await messaging.sendEachForMulticast({
            tokens,
            notification: { title, body },
            data: {
              type: 'personal_entry_reminder',
              uid,
              dueDate: today.key,
              dueCount: String(dueDocs.length)
            }
          })

          if (response.successCount > 0) {
            hasSuccess = true
            notificationsSent += response.successCount
          }

          response.responses.forEach((item, index) => {
            if (item.success) return
            const code = item.error?.code || ''
            if (
              code === 'messaging/registration-token-not-registered' ||
              code === 'messaging/invalid-registration-token'
            ) {
              invalid.add(tokens[index])
            }
          })
        }

        if (invalid.size) {
          const refsToDelete = tokenDocs
            .filter((item) => invalid.has(item.token))
            .flatMap((item) => item.refs)
          await Promise.all(
            refsToDelete.map((ref) => ref.delete().catch(() => null))
          )
        }

        if (hasSuccess) {
          usersNotified += 1
          const batch = db.batch()
          for (const doc of dueDocs) {
            batch.set(
              doc.ref,
              {
                lastReminderAt: now,
                updatedAt: now
              },
              { merge: true }
            )
          }
          await batch.commit()
        }
      }

      logger.info('Lembretes pessoais enviados.', {
        usersNotified,
        notificationsSent,
        date: today.key
      })
    } catch (error) {
      logger.error('Falha ao enviar lembretes de personal_entries', {
        error: error?.message || error
      })
    }
  }
)

async function getStoreRecipients(storeId) {
  const storeRef = db.collection('stores').doc(storeId)
  const storeSnap = await storeRef.get()
  if (!storeSnap.exists) return []

  const ownerUid = storeSnap.data()?.ownerUid || null
  const membersSnap = await storeRef.collection('members').get()
  const memberUids = membersSnap.docs.map((d) => d.id)
  return uniq([ownerUid, ...memberUids])
}

async function getTokensForStoreUsers(storeId, userUids) {
  if (!userUids.length) return []
  const tokenDocsPerUser = await Promise.all(
    userUids.map((uid) =>
      getUserTokenDocs(db.collection('users').doc(uid), { storeId })
    )
  )
  return tokenDocsPerUser.flat()
}

exports.sendPushFromNotificationEvents = onDocumentCreated(
  {
    document: 'notification_events/{eventId}',
    region: 'southamerica-east1'
  },
  async (event) => {
    const data = event.data?.data()
    if (!data) return

    const storeId = String(data.storeId || '')
    const title = String(data.title || 'Nova notificacao')
    const body = String(data.body || '')
    const type = String(data.type || 'generic')
    if (!storeId) return

    try {
      const recipients = await getStoreRecipients(storeId)
      if (!recipients.length) return

      const tokenDocs = await getTokensForStoreUsers(storeId, recipients)
      if (!tokenDocs.length) return

      const uniqueTokens = uniq(tokenDocs.map((t) => t.token))
      const batches = chunk(uniqueTokens, 500)
      const invalid = new Set()

      for (const tokens of batches) {
        const response = await messaging.sendEachForMulticast({
          tokens,
          notification: { title, body },
          data: {
            storeId,
            type
          }
        })

        response.responses.forEach((item, index) => {
          if (item.success) return
          const code = item.error?.code || ''
          if (
            code === 'messaging/registration-token-not-registered' ||
            code === 'messaging/invalid-registration-token'
          ) {
            invalid.add(tokens[index])
          }
        })
      }

      if (invalid.size) {
        const refsToDelete = tokenDocs
          .filter((t) => invalid.has(t.token))
          .flatMap((t) => t.refs)
        await Promise.all(
          refsToDelete.map((ref) => ref.delete().catch(() => null))
        )
      }
    } catch (error) {
      logger.error('Falha ao enviar push a partir de notification_events', {
        error: error?.message || error
      })
    }
  }
)

// ============================================================================
// SUBSCRIPTION SYSTEM - Sistema de Assinatura
// ============================================================================

// Helper function to add months to a date
function addMonths(date, months) {
  const result = new Date(date)
  result.setMonth(result.getMonth() + months)
  return result
}

// Helper function to get plan details
function getPlanDetails(plan) {
  const plans = {
    monthly: {
      name: 'Plano Mensal',
      description: 'Assinatura mensal do Bloquinho Digital',
      price: 29.90,
      months: 1
    },
    quarterly: {
      name: 'Plano Trimestral',
      description: 'Assinatura trimestral do Bloquinho Digital (3 meses)',
      price: 49.90,
      months: 3
    },
    annual: {
      name: 'Plano Anual',
      description: 'Assinatura anual do Bloquinho Digital (12 meses)',
      price: 299.90,
      months: 12
    }
  }
  return plans[plan] || null
}

// ============================================================================
// 1. Initialize User Subscription (onCreate trigger)
// ============================================================================
exports.initializeUserSubscription = onDocumentCreated(
  {
    document: 'users/{userId}',
    region: 'southamerica-east1'
  },
  async (event) => {
    const userId = event.params.userId
    const now = new Date().toISOString()
    
    try {
      // Verificar se já existe subscription
      const subscriptionDoc = await db.collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .get()
      
      if (subscriptionDoc.exists) {
        logger.info(`Subscription already exists for user ${userId}`)
        return
      }

      // Adicionar 2 meses de trial
      const expirationDate = addMonths(new Date(), 2).toISOString()

      await db.collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .set({
          plan: 'free',
          status: 'trial',
          startDate: now,
          expirationDate: expirationDate,
          trialUsed: true,
          autoRenew: false,
          createdAt: now,
          updatedAt: now
        })

      logger.info(`Initialized trial subscription for user ${userId}`, {
        userId,
        expirationDate: expirationDate
      })
    } catch (error) {
      logger.error('Error initializing user subscription', {
        userId,
        error: error?.message || error
      })
    }
  }
)

// ============================================================================
// 2. Create Payment Preference (Callable function)
// ============================================================================
exports.createPaymentPreference = onCall(
  {
    region: 'southamerica-east1'
  },
  async (request) => {
    // Validar autenticação
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User not authenticated')
    }

    const { plan } = request.data
    const userId = request.auth.uid

    // Validar plano
    const validPlans = ['monthly', 'quarterly', 'annual']
    if (!validPlans.includes(plan)) {
      throw new HttpsError('invalid-argument', 'Invalid plan. Must be: monthly, quarterly, or annual')
    }

    try {
      const planDetails = getPlanDetails(plan)
      const externalReference = `${userId}_${plan}_${Date.now()}`

      // Get configuration from environment
      const accessToken = process.env.MERCADOPAGO_ACCESS_TOKEN
      const baseUrl = process.env.APP_BASE_URL || 'https://bloquinhodigital.web.app'
      const functionsUrl = process.env.FUNCTIONS_URL || 'https://southamerica-east1-bloquinhodigital.cloudfunctions.net'

      if (!accessToken) {
        throw new HttpsError('failed-precondition', 'Mercado Pago credentials not configured')
      }

      // Configurar preferência
      const preference = {
        items: [{
          title: planDetails.name,
          description: planDetails.description,
          unit_price: planDetails.price,
          quantity: 1,
          currency_id: 'BRL'
        }],
        back_urls: {
          success: `${baseUrl}/pagamento/sucesso`,
          failure: `${baseUrl}/pagamento/falha`,
          pending: `${baseUrl}/pagamento/pendente`
        },
        auto_return: 'approved',
        external_reference: externalReference,
        notification_url: `${functionsUrl}/mercadoPagoWebhook`,
        metadata: {
          user_id: userId,
          plan: plan
        }
      }

      // Criar preferência no Mercado Pago
      const mercadopago = new MercadoPagoConfig({
        accessToken: accessToken
      })

      const preferenceClient = new Preference(mercadopago)
      const result = await preferenceClient.create({ body: preference })

      // Salvar transação pendente
      await db.collection('users')
        .doc(userId)
        .collection('transactions')
        .add({
          preferenceId: result.id,
          plan: plan,
          amount: planDetails.price,
          status: 'pending',
          externalReference: externalReference,
          createdAt: admin.firestore.FieldValue.serverTimestamp()
        })

      logger.info('Payment preference created', {
        userId,
        plan,
        preferenceId: result.id
      })

      return {
        preferenceId: result.id,
        initPoint: result.init_point // URL para redirecionar
      }
    } catch (error) {
      logger.error('Error creating payment preference', {
        userId,
        plan,
        error: error?.message || error
      })
      throw new HttpsError('internal', 'Failed to create payment preference')
    }
  }
)

// ============================================================================
// 3. Update Subscription (Helper function)
// ============================================================================
async function updateSubscription(userId, plan) {
  const subscriptionRef = db.collection('users')
    .doc(userId)
    .collection('subscription')
    .doc('current')

  const subscriptionDoc = await subscriptionRef.get()
  const now = new Date().toISOString()
  const planDetails = getPlanDetails(plan)

  let newExpirationDate

  if (subscriptionDoc.exists) {
    const currentData = subscriptionDoc.data()
    const currentExpirationStr = currentData.expirationDate
    const currentExpiration = new Date(currentExpirationStr)
    
    // Se ainda não expirou, adiciona ao tempo atual
    if (currentExpiration > new Date()) {
      newExpirationDate = addMonths(currentExpiration, planDetails.months).toISOString()
    } else {
      // Se já expirou, começa de agora
      newExpirationDate = addMonths(new Date(), planDetails.months).toISOString()
    }

    await subscriptionRef.update({
      plan: plan,
      status: 'active',
      expirationDate: newExpirationDate,
      updatedAt: now
    })

    logger.info('Subscription updated', {
      userId,
      plan,
      newExpirationDate: newExpirationDate
    })
  } else {
    // Primeira assinatura
    newExpirationDate = addMonths(new Date(), planDetails.months).toISOString()

    await subscriptionRef.set({
      plan: plan,
      status: 'active',
      startDate: now,
      expirationDate: newExpirationDate,
      trialUsed: false,
      autoRenew: false,
      createdAt: now,
      updatedAt: now
    })

    logger.info('Subscription created', {
      userId,
      plan,
      newExpirationDate: newExpirationDate
    })
  }
}

// ============================================================================
// 4. Mercado Pago Webhook Handler
// ============================================================================
exports.mercadoPagoWebhook = onRequest(
  {
    region: 'southamerica-east1'
  },
  async (req, res) => {
    // Validar método
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed')
      return
    }

    // Log do webhook para auditoria
    const webhookLog = await db.collection('webhooks').add({
      type: req.body.type || 'unknown',
      action: req.body.action || 'unknown',
      data: req.body,
      processed: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    })

    try {
      // Processar apenas eventos de pagamento
      if (req.body.type === 'payment') {
        const paymentId = req.body.data?.id
        
        if (!paymentId) {
          logger.warn('Webhook received without payment ID')
          res.status(200).send('OK - No payment ID')
          return
        }

        // Buscar detalhes do pagamento
        const accessToken = process.env.MERCADOPAGO_ACCESS_TOKEN
        if (!accessToken) {
          throw new Error('Mercado Pago credentials not configured')
        }

        const mercadopago = new MercadoPagoConfig({
          accessToken: accessToken
        })
        
        const paymentClient = new Payment(mercadopago)
        const payment = await paymentClient.get({ id: paymentId })

        // Extrair informações
        const externalReference = payment.external_reference
        const status = payment.status
        
        if (!externalReference) {
          logger.warn('Payment without external reference', { paymentId })
          res.status(200).send('OK - No external reference')
          return
        }

        const [userId, plan] = externalReference.split('_')

        // Atualizar transação
        const transactionQuery = await db.collection('users')
          .doc(userId)
          .collection('transactions')
          .where('externalReference', '==', externalReference)
          .limit(1)
          .get()

        if (!transactionQuery.empty) {
          const transactionDoc = transactionQuery.docs[0]
          await transactionDoc.ref.update({
            mercadoPagoId: paymentId,
            status: status,
            paymentMethod: payment.payment_method_id || 'unknown',
            paymentDetails: {
              cardBrand: payment.payment_method?.issuer_id || null,
              lastFourDigits: payment.card?.last_four_digits || null
            },
            processedAt: admin.firestore.FieldValue.serverTimestamp()
          })

          logger.info('Transaction updated', {
            userId,
            paymentId,
            status
          })
        }

        // Se aprovado, atualizar assinatura
        if (status === 'approved') {
          await updateSubscription(userId, plan)
          logger.info('Subscription activated after payment', {
            userId,
            plan,
            paymentId
          })
        }

        // Marcar webhook como processado
        await webhookLog.update({
          processed: true,
          processedAt: admin.firestore.FieldValue.serverTimestamp()
        })
      }

      res.status(200).send('OK')
    } catch (error) {
      logger.error('Error processing webhook', {
        error: error?.message || error,
        body: req.body
      })
      
      // Salvar erro no log
      await webhookLog.update({
        error: error?.message || String(error),
        processedAt: admin.firestore.FieldValue.serverTimestamp()
      })

      res.status(500).send('Error processing webhook')
    }
  }
)

// ============================================================================
// 5. Check Subscription Status (Scheduled daily)
// ============================================================================
// ============================================================================
// 6. Initialize Existing Users Subscriptions (Callable - Admin only)
// ============================================================================
exports.initializeExistingUsersSubscriptions = onCall(
  {
    region: 'southamerica-east1'
  },
  async (request) => {
    // Esta função deve ser chamada apenas uma vez para inicializar
    // assinaturas de usuários que já existiam antes do sistema

    try {
      // Buscar todos os usuários
      const usersSnapshot = await db.collection('users').get();
      let initialized = 0;
      let skipped = 0;

      // Usar strings ISO 8601 para datas (100% compatível com Flutter Web)
      const now = new Date().toISOString();
      const expirationDate = addMonths(new Date(), 2).toISOString();

      // Processar em lotes para evitar problemas
      const promises = [];

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        
        // Criar promise para verificar e criar assinatura
        const promise = (async () => {
          try {
            // Verificar se já tem assinatura
            const subscriptionDoc = await db.collection('users')
              .doc(userId)
              .collection('subscription')
              .doc('current')
              .get();

            if (subscriptionDoc.exists) {
              return { userId, status: 'skipped' };
            }

            // Criar assinatura de trial usando strings ISO 8601
            await db.collection('users')
              .doc(userId)
              .collection('subscription')
              .doc('current')
              .set({
                plan: 'free',
                status: 'trial',
                startDate: now,
                expirationDate: expirationDate,
                trialUsed: true,
                autoRenew: false,
                createdAt: now,
                updatedAt: now
              });

            return { userId, status: 'initialized' };
          } catch (error) {
            logger.error(`Error processing user ${userId}`, { error: error?.message });
            return { userId, status: 'error', error: error?.message };
          }
        })();

        promises.push(promise);
      }

      // Aguardar todas as operações
      const results = await Promise.all(promises);

      // Contar resultados
      results.forEach(result => {
        if (result.status === 'initialized') {
          initialized++;
        } else if (result.status === 'skipped') {
          skipped++;
        }
      });

      logger.info(`Subscription initialization complete`, {
        initialized,
        skipped,
        total: results.length
      });

      // Retornar apenas dados primitivos (números e strings)
      return {
        success: true,
        initialized: initialized,
        skipped: skipped,
        message: `Initialized ${initialized} users, skipped ${skipped} users that already had subscriptions`
      };
    } catch (error) {
      logger.error('Error initializing existing users subscriptions', {
        error: error?.message || error
      });
      throw new HttpsError('internal', `Failed to initialize subscriptions: ${error.message}`);
    }
  }
);

exports.checkSubscriptionStatus = onSchedule(
  {
    schedule: 'every 24 hours',
    timeZone: 'America/Sao_Paulo',
    region: 'southamerica-east1'
  },
  async () => {
    const now = new Date()
    
    try {
      // Buscar todas as assinaturas ativas ou em trial
      const subscriptionsSnapshot = await db.collectionGroup('subscription')
        .where('status', 'in', ['active', 'trial'])
        .get()

      if (subscriptionsSnapshot.empty) {
        logger.info('No active subscriptions to check')
        return
      }

      const batch = db.batch()
      let updatedCount = 0

      subscriptionsSnapshot.forEach((doc) => {
        const data = doc.data()
        const expirationDateStr = data.expirationDate

        if (!expirationDateStr) {
          logger.warn('Subscription without expiration date', { docId: doc.id })
          return
        }

        const expirationDate = new Date(expirationDateStr)

        // Se expirou, atualizar status
        if (expirationDate < now) {
          batch.update(doc.ref, {
            status: 'expired',
            updatedAt: now.toISOString()
          })
          updatedCount++
        }
      })

      if (updatedCount > 0) {
        await batch.commit()
        logger.info(`Updated ${updatedCount} expired subscriptions`)
      } else {
        logger.info('No expired subscriptions found')
      }
    } catch (error) {
      logger.error('Error checking subscription status', {
        error: error?.message || error
      })
    }
  }
)
