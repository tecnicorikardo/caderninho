import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_formatters.dart';

class VitrinePage extends StatelessWidget {
  const VitrinePage({super.key, required this.slug});

  final String slug;

  Future<_StoreLookupResult?> _findStoreBySlug() async {
    final normalized = _normalizeSlugPath(slug);
    if (normalized.isEmpty) return null;
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('storeSlug', isEqualTo: normalized)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    final doc = query.docs.first;
    final data = doc.data();
    return _StoreLookupResult(
      userId: doc.id,
      storeName: (data['storeName'] ?? 'Vitrine Digital').toString(),
      phone: (data['phone'] ?? '').toString(),
      storeSlug: (data['storeSlug'] ?? '').toString(),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('products')
        .where('showInWeb', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _openWhatsApp({
    required String phone,
    required String text,
  }) async {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return;
    final encodedText = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/$digitsOnly?text=$encodedText');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_StoreLookupResult?>(
        future: _findStoreBySlug(),
        builder: (context, storeSnapshot) {
          if (storeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (storeSnapshot.hasError) {
            return const _VitrineErrorState();
          }

          final storeData = storeSnapshot.data;
          if (storeData == null) {
            return const _EmptyStoreState();
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _productsStream(storeData.userId),
            builder: (context, productsSnapshot) {
              if (productsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productsSnapshot.hasError) {
                return const _VitrineErrorState();
              }

              final docs = productsSnapshot.data?.docs ?? [];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 1320
                      ? 4
                      : width >= 980
                      ? 3
                      : width >= 640
                      ? 2
                      : 1;

                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _StoreHero(
                            store: storeData,
                            productsCount: docs.length,
                            onWhatsAppTap: storeData.phone.trim().isEmpty
                                ? null
                                : () => _openWhatsApp(
                                    phone: storeData.phone,
                                    text: 'Ola! Vim pela vitrine online.',
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                docs.isEmpty
                                    ? 'Nenhum produto publicado'
                                    : 'Produtos em destaque',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),
                          if (docs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 42),
                              child: _NoProductsCard(),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: width >= 640
                                          ? 0.74
                                          : 0.86,
                                    ),
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();
                                  final name = (data['name'] ?? 'Produto')
                                      .toString();
                                  final price =
                                      (data['salePrice'] as num?)?.toDouble() ??
                                      0;
                                  final images = _extractImageList(data);
                                  return _AnimatedProductCard(
                                    delayFactor: index,
                                    child: _ProductCard(
                                      name: name,
                                      price: price,
                                      imageUrls: images,
                                      onWhatsAppTap:
                                          storeData.phone.trim().isEmpty
                                          ? null
                                          : () => _openWhatsApp(
                                              phone: storeData.phone,
                                              text:
                                                  'Tenho interesse no produto $name.',
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

List<String> _extractImageList(Map<String, dynamic> data) {
  final urls = <String>{};
  final thumb = (data['thumbnailUrl'] ?? '').toString().trim();
  final image = (data['imageUrl'] ?? '').toString().trim();
  if (thumb.isNotEmpty) urls.add(thumb);
  if (image.isNotEmpty) urls.add(image);

  final galleryRaw = data['galleryUrls'];
  if (galleryRaw is List) {
    for (final item in galleryRaw) {
      final candidate = item.toString().trim();
      if (candidate.isNotEmpty) urls.add(candidate);
    }
  } else if (galleryRaw is String && galleryRaw.trim().isNotEmpty) {
    for (final item in galleryRaw.split(',')) {
      final candidate = item.trim();
      if (candidate.isNotEmpty) urls.add(candidate);
    }
  }
  return urls.toList();
}

String _normalizeSlugPath(String value) {
  final lowercase = value.trim().toLowerCase();
  return lowercase
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp('-{2,}'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

class _StoreHero extends StatelessWidget {
  const _StoreHero({
    required this.store,
    required this.productsCount,
    this.onWhatsAppTap,
  });

  final _StoreLookupResult store;
  final int productsCount;
  final VoidCallback? onWhatsAppTap;

  @override
  Widget build(BuildContext context) {
    final canCall = onWhatsAppTap != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF0EA5A5), Color(0xFFF97316)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2611555A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0x1FFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 80,
            bottom: -26,
            child: Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: Color(0x1AFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vitrine Digital',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 13,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                store.storeName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroChip(
                    icon: Icons.storefront_outlined,
                    text: store.storeSlug,
                  ),
                  _HeroChip(
                    icon: Icons.inventory_2_outlined,
                    text: '$productsCount produto(s)',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onWhatsAppTap,
                style: FilledButton.styleFrom(
                  backgroundColor: canCall
                      ? const Color(0xFF052E2B)
                      : const Color(0x66374151),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.chat_outlined),
                label: Text(
                  canCall ? 'Falar no WhatsApp' : 'Contato indisponivel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x2EFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedProductCard extends StatelessWidget {
  const _AnimatedProductCard({required this.child, required this.delayFactor});

  final Widget child;
  final int delayFactor;

  @override
  Widget build(BuildContext context) {
    final start = (delayFactor * 0.06).clamp(0.0, 0.7);
    final end = (start + 0.26).clamp(0.2, 1.0);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        final intervalValue = Interval(
          start,
          end,
          curve: Curves.easeOutCubic,
        ).transform(value);
        return Transform.translate(
          offset: Offset(0, (1 - intervalValue) * 26),
          child: Opacity(opacity: intervalValue, child: child),
        );
      },
      child: child,
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.name,
    required this.price,
    required this.imageUrls,
    this.onWhatsAppTap,
  });

  final String name;
  final double price;
  final List<String> imageUrls;
  final VoidCallback? onWhatsAppTap;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: _isHovering ? 1.015 : 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isHovering
                    ? const Color(0x332F3A45)
                    : const Color(0x1C0F172A),
                blurRadius: _isHovering ? 22 : 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _ProductImageCarousel(imageUrls: widget.imageUrls),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xEE111827),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          AppFormatters.currency(widget.price),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.currency(widget.price),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: widget.onWhatsAppTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0E7490),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.chat_outlined),
                            label: const Text('WhatsApp'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductImageCarousel extends StatefulWidget {
  const _ProductImageCarousel({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoSlide();
  }

  @override
  void didUpdateWidget(covariant _ProductImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls.length != widget.imageUrls.length) {
      _index = 0;
      _timer?.cancel();
      _startAutoSlide();
    }
  }

  void _startAutoSlide() {
    if (widget.imageUrls.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % widget.imageUrls.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
      _index = next;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: 190,
        color: const Color(0xFFE2E8F0),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, size: 38),
      );
    }

    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (value) => setState(() => _index = value),
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              final url = widget.imageUrls[index];
              return _NetworkProductImage(url: url);
            },
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 8,
              child: Row(
                children: List.generate(widget.imageUrls.length, (dotIndex) {
                  final active = dotIndex == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: active ? 16 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFFFFFFF)
                          : const Color(0x80FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _NetworkProductImage extends StatelessWidget {
  const _NetworkProductImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 450),
            opacity: frame == null ? 0 : 1,
            child: child,
          );
        },
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image_outlined, size: 34)),
      ),
    );
  }
}

class _NoProductsCard extends StatelessWidget {
  const _NoProductsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF0E7490)),
          SizedBox(height: 12),
          Text(
            'Nenhum produto foi publicado na vitrine ainda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Ative "Exibir na Vitrine Online" no cadastro de produtos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}

class _EmptyStoreState extends StatelessWidget {
  const _EmptyStoreState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_mall_directory_outlined, size: 44),
            SizedBox(height: 10),
            Text(
              'Loja nao encontrada ou inativa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Verifique o link da vitrine ou peça um novo endereco para a loja.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _VitrineErrorState extends StatelessWidget {
  const _VitrineErrorState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_outlined, size: 44),
            SizedBox(height: 10),
            Text(
              'Nao foi possivel abrir a vitrine',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Tente atualizar a pagina. Se continuar, gere novamente o link da vitrine nas configuracoes da loja.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreLookupResult {
  const _StoreLookupResult({
    required this.userId,
    required this.storeName,
    required this.phone,
    required this.storeSlug,
  });

  final String userId;
  final String storeName;
  final String phone;
  final String storeSlug;
}
