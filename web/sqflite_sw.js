// sqflite_sw.js - Service Worker para SQLite no Web
// Baseado na implementação do sqflite_common_ffi_web

importScripts('https://unpkg.com/sql.js@1.8.0/dist/sql-wasm.js');

let db = null;
let isInitialized = false;

// Inicializar SQLite
async function initDatabase() {
  if (isInitialized) return;
  
  try {
    const SQL = await initSqlJs({
      locateFile: file => `https://unpkg.com/sql.js@1.8.0/dist/${file}`
    });
    
    db = new SQL.Database();
    isInitialized = true;
    
    self.postMessage({
      type: 'init',
      success: true
    });
  } catch (error) {
    self.postMessage({
      type: 'init',
      success: false,
      error: error.message
    });
  }
}

// Executar comando SQL
function executeSql(command, params = []) {
  if (!isInitialized || !db) {
    throw new Error('Database not initialized');
  }
  
  try {
    const result = db.exec(command, params);
    return {
      success: true,
      result: result
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

// Exportar banco
function exportDatabase() {
  if (!isInitialized || !db) {
    throw new Error('Database not initialized');
  }
  
  const data = db.export();
  return {
    success: true,
    data: data
  };
}

// Importar banco
function importDatabase(data) {
  if (!isInitialized) {
    throw new Error('Database not initialized');
  }
  
  try {
    db = new SQL.Database(data);
    return {
      success: true
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

// Listener para mensagens do main thread
self.addEventListener('message', async function(e) {
  const { type, id, command, params, data } = e.data;
  
  try {
    let result;
    
    switch (type) {
      case 'init':
        await initDatabase();
        break;
        
      case 'exec':
        result = executeSql(command, params);
        self.postMessage({
          type: 'response',
          id: id,
          ...result
        });
        break;
        
      case 'export':
        result = exportDatabase();
        self.postMessage({
          type: 'response',
          id: id,
          ...result
        });
        break;
        
      case 'import':
        result = importDatabase(data);
        self.postMessage({
          type: 'response',
          id: id,
          ...result
        });
        break;
        
      default:
        self.postMessage({
          type: 'response',
          id: id,
          success: false,
          error: 'Unknown command type'
        });
    }
  } catch (error) {
    self.postMessage({
      type: 'response',
      id: id,
      success: false,
      error: error.message
    });
  }
});

// Inicializar automaticamente
initDatabase(); 