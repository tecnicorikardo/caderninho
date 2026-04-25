import { saveAs } from "@/lib/webfile";

type TemplateMode = "simple" | "full";

function applyHeaderStyle(row: any) {
  row.font = { bold: true, color: { argb: "FFFFFFFF" } };
  row.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF111827" } };
  row.alignment = { vertical: "middle", horizontal: "center" };
  row.height = 22;
}

export async function downloadWorkbookTemplate(mode: TemplateMode) {
  const excelJSImport = await import("exceljs");
  const ExcelJS = excelJSImport.default;

  const wb = new ExcelJS.Workbook();
  wb.creator = "bloquinhodigital";
  wb.created = new Date();

  const config = wb.addWorksheet("Config");
  config.getCell("A1").value = "Nível (para fórmulas)";
  config.getCell("B1").value = "Semente";
  config.getCell("A3").value = "Marca";
  config.getCell("B3").value = "Semente";
  config.getCell("C3").value = "Bronze";
  config.getCell("D3").value = "Prata";
  config.getCell("E3").value = "Ouro";
  config.getCell("F3").value = "Diamante";
  applyHeaderStyle(config.getRow(3));
  config.addRow(["Natura", 0.2, 0.3, 0.3, 0.32, 0.35]);
  config.addRow(["Avon", 0.2, 0.3, 0.35, 0.38, 0.4]);
  config.addRow(["Casa & Estilo", 0.15, 0.15, 0.15, 0.15, 0.2]);

  config.getColumn(1).width = 20;
  for (let i = 2; i <= 6; i += 1) config.getColumn(i).width = 12;

  const customers = wb.addWorksheet("Clientes");
  customers.addRow(["name*", "phone*", "email", "address"]);
  applyHeaderStyle(customers.getRow(1));
  customers.getColumn(1).width = 26;
  customers.getColumn(2).width = 18;
  customers.getColumn(3).width = 28;
  customers.getColumn(4).width = 32;

  const products = wb.addWorksheet("Produtos");
  products.addRow(["name*", "brand*", "code", "costPrice", "sellingPrice", "suggestedSellingPrice"]);
  applyHeaderStyle(products.getRow(1));
  products.getColumn(1).width = 28;
  products.getColumn(2).width = 16;
  products.getColumn(3).width = 14;
  products.getColumn(4).width = 12;
  products.getColumn(5).width = 12;
  products.getColumn(6).width = 20;
  products.getColumn(4).numFmt = '"R$" #,##0.00';
  products.getColumn(5).numFmt = '"R$" #,##0.00';
  products.getColumn(6).numFmt = '"R$" #,##0.00';

  const inventory = wb.addWorksheet("Estoque");
  inventory.addRow([
    "productCode",
    "productName*",
    "brand*",
    "quantity*",
    "costPrice*",
    "sellingPrice*",
    "expiryDate* (YYYY-MM-DD)",
    "daysToExpire",
  ]);
  applyHeaderStyle(inventory.getRow(1));
  inventory.getColumn(1).width = 14;
  inventory.getColumn(2).width = 28;
  inventory.getColumn(3).width = 16;
  inventory.getColumn(4).width = 10;
  inventory.getColumn(5).width = 12;
  inventory.getColumn(6).width = 12;
  inventory.getColumn(7).width = 18;
  inventory.getColumn(8).width = 12;
  inventory.getColumn(5).numFmt = '"R$" #,##0.00';
  inventory.getColumn(6).numFmt = '"R$" #,##0.00';

  if (mode === "full") {
    // Fórmulas de sugestão de preço: custo / (1 - margem)
    // margin = lookup(brand, nível) na aba Config.
    // Excel armazena fórmulas em inglês dentro do arquivo.
    const formulaSuggestedPrice =
      'IF(D{row}="", "", D{row}/(1-INDEX(Config!$B$4:$F$6, MATCH(B{row},Config!$A$4:$A$6,0), MATCH(Config!$B$1,Config!$B$3:$F$3,0))))';
    for (let row = 2; row <= 501; row += 1) {
      products.getCell(`F${row}`).value = { formula: formulaSuggestedPrice.replaceAll("{row}", String(row)) };
    }

    for (let row = 2; row <= 501; row += 1) {
      inventory.getCell(`H${row}`).value = { formula: `IF(G${row}="", "", G${row}-TODAY())` };
    }
  }

  const buf = await wb.xlsx.writeBuffer();
  const name = mode === "full" ? "modelo-completo.xlsx" : "modelo-simples.xlsx";
  saveAs(new Blob([buf]), name);
}
