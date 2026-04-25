import type { User } from "firebase/auth";
import DashboardLayout from "@/ui/DashboardLayout";
import StockHealthWidget from "@/ui/StockHealthWidget";

export default function DashboardPage({ user }: { user: User }) {
  return (
    <DashboardLayout title="Dashboard">
      <StockHealthWidget uid={user.uid} />
    </DashboardLayout>
  );
}

