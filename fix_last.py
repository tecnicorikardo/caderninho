raw = open('web/src/pages/SalesPage.tsx','rb').read()
raw = raw.replace(b'\xc3\xa2\xc5\xa1\xc2\xa0', b'\xe2\x9a\xa0 ')
raw = raw.replace(b'\xc3\xa2\xc5\x93...', b'ok ')
open('web/src/pages/SalesPage.tsx','wb').write(raw)
c = open('web/src/pages/SalesPage.tsx',encoding='utf-8',errors='replace').read()
bad = [l for l in c.split('\n') if '\ufffd' in l or 'â' in l]
print(len(bad), 'bad lines')
