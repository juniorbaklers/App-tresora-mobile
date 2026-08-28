"use client";
import * as React from "react";
import { hasPermission, type Permission, type Role } from "@/lib/roles";

type RoleContextValue = {
  role: Role;
  setRole: (role: Role) => void;
  can: (permission: Permission) => boolean;
};

const RoleContext = React.createContext<RoleContextValue | null>(null);

export function RoleProvider({
  children,
  initialRole = "admin",
}: {
  children: React.ReactNode;
  initialRole?: Role;
}) {
  const [role, setRole] = React.useState<Role>(initialRole);
  const value = React.useMemo<RoleContextValue>(
    () => ({ role, setRole, can: (p) => hasPermission(role, p) }),
    [role]
  );
  return <RoleContext.Provider value={value}>{children}</RoleContext.Provider>;
}

export function useRole() {
  const ctx = React.useContext(RoleContext);
  if (!ctx) throw new Error("useRole must be used inside <RoleProvider>");
  return ctx;
}

/** Renders children only when the current role holds every listed permission. */
export function Gate({
  permission,
  fallback = null,
  children,
}: {
  permission: Permission | Permission[];
  fallback?: React.ReactNode;
  children: React.ReactNode;
}) {
  const { can } = useRole();
  const list = Array.isArray(permission) ? permission : [permission];
  return <>{list.every(can) ? children : fallback}</>;
}
