import type { Timestamp, FieldValue } from "firebase/firestore";

export type ServerTimestamp = FieldValue;

export type GrowthLevel = "Semente" | "Bronze" | "Prata" | "Ouro" | "Diamante";
export type Brand = "Natura" | "Avon" | "Casa & Estilo" | "Outra";

export type UserProfile = {
  createdAt: Timestamp | ServerTimestamp;
  updatedAt: Timestamp | ServerTimestamp;
  onboardedAt?: Timestamp | ServerTimestamp | null;
  // growthLevel é controlado pelo servidor (regras impedem update pelo front-end).
  growthLevel?: GrowthLevel;
};

export type Customer = {
  name: string;
  phone: string;
  phoneNormalized: string;
  email?: string | null;
  address?: string | null;
  balanceCents: number;
  createdAt: Timestamp | ServerTimestamp;
  updatedAt: Timestamp | ServerTimestamp;
};

export type Product = {
  name: string;
  brand: string;
  code?: string | null;
  costPriceCents?: number | null;
  sellingPriceCents?: number | null;
  createdAt: Timestamp | ServerTimestamp;
  updatedAt: Timestamp | ServerTimestamp;
};

export type InventoryItem = {
  productId: string;
  sku?: string | null;
  productName: string;
  brand: string;
  quantity: number;
  costPriceCents: number;
  sellingPriceCents: number;
  expiryDate: Timestamp;
  createdAt: Timestamp | ServerTimestamp;
  updatedAt: Timestamp | ServerTimestamp;
};

export type PaymentType = "cash" | "pix" | "card" | "fiado" | "installments";

export type SaleItem = {
  inventoryId?: string | null;
  productId: string;
  productName: string;
  quantity: number;
  unitPriceCents: number;
  unitCostCents: number;
  expiryDate?: Timestamp | null;
};

export type Sale = {
  customerId: string;
  items: SaleItem[];
  totalCents: number;
  paidCents: number;
  paymentType: PaymentType;
  createdAt: Timestamp | ServerTimestamp;
  updatedAt: Timestamp | ServerTimestamp;
};

export type ReceivableStatus = "pending" | "partial" | "paid" | "late";

export type Receivable = {
  saleId: string;
  customerId: string;
  dueDate: Timestamp;
  amountCents: number;
  paidCents: number;
  status: ReceivableStatus;
  createdAt: Timestamp | ServerTimestamp;
  updatedAt: Timestamp | ServerTimestamp;
};

