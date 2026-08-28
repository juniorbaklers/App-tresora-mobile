import type { Metadata } from "next";
import { Schibsted_Grotesk } from "next/font/google";
import "./globals.css";
import { RoleProvider } from "@/components/role-provider";

const sans = Schibsted_Grotesk({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
  variable: "--font-sans",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Trésora — Gestion financière multi-espace",
  description:
    "Cotisations, dépenses, dîmes et rapports pour vos espaces, avec justificatifs et piste d'audit.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr" className={sans.variable} suppressHydrationWarning>
      <body>
        <RoleProvider initialRole="admin">{children}</RoleProvider>
      </body>
    </html>
  );
}
