"use client";

import * as React from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Eye, EyeOff, Loader2, Phone, Mail } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { Switch } from "@/components/ui/switch";
import { useRole } from "@/components/role-provider";
import type { Role } from "@/lib/roles";

export function LoginForm() {
  const router = useRouter();
  const { setRole } = useRole();
  const [method, setMethod] = React.useState<"phone" | "email">("phone");
  const [showPassword, setShowPassword] = React.useState(false);
  const [pending, setPending] = React.useState(false);
  const [demoRole, setDemoRole] = React.useState<Role>("admin");

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    // Placeholder: replace with the real auth call.
    await new Promise((r) => setTimeout(r, 700));
    setRole(demoRole);
    router.push("/tableau-de-bord");
  }

  return (
    <form onSubmit={onSubmit} className="grid gap-6">
      <Tabs value={method} onValueChange={(v) => setMethod(v as typeof method)}>
        <TabsList className="w-full">
          <TabsTrigger value="phone">
            <Phone /> Téléphone
          </TabsTrigger>
          <TabsTrigger value="email">
            <Mail /> E-mail
          </TabsTrigger>
        </TabsList>

        <TabsContent value="phone" className="mt-6">
          <div className="grid gap-2">
            <Label htmlFor="phone">Numéro de téléphone</Label>
            <div className="flex gap-2">
              <div className="flex h-11 shrink-0 items-center rounded-md border border-input bg-muted px-3 text-sm font-medium text-graphite-600">
                +225
              </div>
              <Input id="phone" name="phone" type="tel" inputMode="tel" autoComplete="tel" placeholder="07 00 00 00 00" required />
            </div>
          </div>
        </TabsContent>

        <TabsContent value="email" className="mt-6">
          <div className="grid gap-2">
            <Label htmlFor="email">Adresse e-mail</Label>
            <Input id="email" name="email" type="email" autoComplete="email" placeholder="vous@exemple.ci" required />
          </div>
        </TabsContent>
      </Tabs>

      <div className="grid gap-2">
        <div className="flex items-baseline justify-between">
          <Label htmlFor="password">Mot de passe</Label>
          <Link href="/mot-de-passe-oublie" className="text-[13px] font-medium">
            Oublié ?
          </Link>
        </div>
        <div className="relative">
          <Input
            id="password"
            name="password"
            type={showPassword ? "text" : "password"}
            autoComplete="current-password"
            placeholder="••••••••"
            className="pr-11"
            required
          />
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            aria-label={showPassword ? "Masquer le mot de passe" : "Afficher le mot de passe"}
            className="absolute right-1 top-1 flex h-9 w-9 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
          >
            {showPassword ? <EyeOff className="size-4" /> : <Eye className="size-4" />}
          </button>
        </div>
      </div>

      <Button type="submit" variant="brand" size="lg" disabled={pending}>
        {pending && <Loader2 className="animate-spin" />}
        {pending ? "Connexion…" : "Se connecter"}
      </Button>

      {/* Demo switch — remove once real auth returns the role */}
      <div className="flex items-center justify-between rounded-lg border border-dashed bg-background px-4 py-3">
        <div>
          <p className="text-[13px] font-medium">Ouvrir en administrateur</p>
          <p className="text-xs text-muted-foreground">Démo : bascule le rôle après connexion.</p>
        </div>
        <Switch
          checked={demoRole === "admin"}
          onCheckedChange={(c) => setDemoRole(c ? "admin" : "member")}
          aria-label="Ouvrir en administrateur"
        />
      </div>
    </form>
  );
}
