import { Logo } from "@/components/brand/logo";
import { ShieldCheck, Wallet, FileSpreadsheet } from "lucide-react";

const points = [
  { icon: Wallet, title: "Un espace par communauté", body: "Cotisations, dîmes et dépenses suivies séparément, sous un même compte." },
  { icon: ShieldCheck, title: "Chaque montant justifié", body: "Reçu attaché, validation à deux niveaux, piste d'audit horodatée." },
  { icon: FileSpreadsheet, title: "Rapports prêts à envoyer", body: "Export PDF, Excel et Word en un clic, en fin de période." },
];

export function AuthShell({ children }: { children: React.ReactNode }) {
  return (
    <div className="grid min-h-dvh lg:grid-cols-[1fr_minmax(480px,44%)]">
      {/* Brand panel — hidden on small screens */}
      <aside className="relative hidden overflow-hidden bg-graphite-900 p-12 lg:flex lg:flex-col lg:justify-between">
        <div
          aria-hidden
          className="pointer-events-none absolute -left-40 -top-40 h-[36rem] w-[36rem] rounded-full bg-brand-gradient opacity-[0.18] blur-3xl"
        />
        <div
          aria-hidden
          className="pointer-events-none absolute -bottom-52 -right-24 h-[30rem] w-[30rem] rounded-full bg-brand-gradient opacity-[0.12] blur-3xl"
        />
        <Logo className="relative h-10 text-white" priority />
        <div className="relative max-w-md">
          <h1 className="text-[2.6rem] font-semibold leading-[1.08] tracking-[-0.02em] text-white">
            La trésorerie de votre communauté,{" "}
            <span className="text-brand-gradient">tenue au clair.</span>
          </h1>
          <ul className="mt-10 grid gap-7">
            {points.map(({ icon: Icon, title, body }) => (
              <li key={title} className="flex gap-4">
                <span className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-white/8 ring-1 ring-white/12">
                  <Icon className="size-[18px] text-primary" />
                </span>
                <div>
                  <p className="text-[15px] font-medium text-white">{title}</p>
                  <p className="mt-1 text-sm leading-relaxed text-white/55">{body}</p>
                </div>
              </li>
            ))}
          </ul>
        </div>
        <p className="relative text-xs text-white/50">
          © {new Date().getFullYear()} Trésora · Abidjan, Côte d'Ivoire
        </p>
      </aside>

      <main className="flex flex-col justify-center bg-graphite-50 px-6 py-12 sm:px-12">
        <div className="mx-auto w-full max-w-[26rem]">
          <div className="mb-10 lg:hidden">
            <Logo className="h-9" priority />
          </div>
          {children}
        </div>
      </main>
    </div>
  );
}
