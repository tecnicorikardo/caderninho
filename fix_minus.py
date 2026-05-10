raw = open('web/src/pages/SalesPage.tsx','rb').read()
raw = raw.replace(b'\xc3\xa2\xcb\x86\xe2\x80\x99', b'-')
open('web/src/pages/SalesPage.tsx','wb').write(raw)
c = open('web/src/pages/SalesPage.tsx',encoding='utf-8',errors='replace').read()
bad = [l for l in c.split('\n') if '\ufffd' in l or 'â' in l]
print(len(bad), 'bad lines remaining')
