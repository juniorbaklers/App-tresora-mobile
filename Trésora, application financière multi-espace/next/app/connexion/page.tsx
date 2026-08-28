import { AuthShell } from "@/components/auth/auth-shell";
import Link from "next/link";
import { LoginForm } from "@/components/auth/login-form";

export default function ConnexionPage() {
  return (
    <AuthShell>
    <div className="animate-fade-up">
      <h2 className="text-2xl font-semibold tracking-[-0.02em]">Content de vous revoir</h2>
      <p className="mt-2 text-sm text-muted-foreground">
        Connectez-vous pour accéder à vos espaces.
      </p>

      <div className="mt-8">
        <LoginForm />
      </div>

      <p className="mt-8 text-center text-sm text-muted-foreground">
        Pas encore de compte ?{" "}
        <Link href="/inscription" className="font-medium">
          Créer un espace
        </Link>
      </p>
    </div>
    </AuthShell>
  );
}
