export type GrowthLevel = "Semente" | "Ouro" | "Diamante";
export type Brand = "Natura" | "Avon" | "Casa & Estilo" | "Outra";

export type BrandMargin = {
  brand: string;
  marginPercent: number;
};

// Timestamp compatível com Supabase (ISO string) e Firebase (objeto Timestamp)
export type AppTimestamp = string | { toDate(): Date; seconds: number };

export type UserProfile = {
  createdAt: AppTimestamp;
  updatedAt: AppTimestamp;
  onboardedAt?: AppTimestamp | null;
  growthLevel?: GrowthLevel;
  brandMargins?: BrandMargin[];
  planStatus?: "free" | "pro";
  planExpiresAt?: AppTimestamp | null;
  themeColor?: string | null;
  cpf?: string | null;
  emailVerified?: boolean;
};

export type Customer = {
  $id?: string;
  name: string;
  phone: string;
  phoneNormalized: string;
  email?: string | null;
  address?: string | null;
  balanceCents: number;
  createdAt: AppTimestamp;
  updatedAt: AppTimestamp;
};

export type Product = {
  $id?: string;
  name: string;
  brand: string;
  code?: string | null;
  costPriceCents?: number | null;
  sellingPriceCents?: number | null;
  createdAt: AppTimestamp;
  updatedAt: AppTimestamp;
};

export type InventoryItem = {
  $id?: string;
  productId: string;
  sku?: string | null;
  productName: string;
  brand: string;
  quantity: number;
  costPriceCents: number;
  sellingPriceCents: number;
  expiryDate: AppTimestamp;
  imageUrl?: string | null;
  createdAt: AppTimestamp;
  updatedAt: AppTimestamp;
};

export type PaymentType = "cash" | "pix" | "card" | "fiado" | "installments";

export type SaleItem = {
  inventoryId?: string | null;
  productId: string;
  productName: string;
  brand: string;
  quantity: number;
  unitPriceCents: number;
  unitCostCents: number;
  expiryDate?: AppTimestamp | null;
};

export type Sale = {
  $id?: string;
  customerId: string;
  items: SaleItem[];
  totalCents: number;
  paidCents: number;
  paymentType: PaymentType;
  createdAt: AppTimestamp;
  updatedAt: AppTimestamp;
};

export type ReceivableStatus = "pending" | "partial" | "paid" | "late";

export type Receivable = {
  $id?: string;
  saleId: string;
  customerId: string;
  dueDate: AppTimestamp;
  amountCents: number;
  paidCents: number;
  status: ReceivableStatus;
  createdAt: AppTimestamp;
  updatedAt: AppTimestamp;
};
