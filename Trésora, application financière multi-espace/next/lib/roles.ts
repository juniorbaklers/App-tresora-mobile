export type Role = "member" | "admin";

export const PERMISSIONS = [
  "space.view", "space.manage", "space.transfer",
  "contribution.view", "contribution.pay", "contribution.create",
  "expense.view", "expense.create", "expense.approve",
  "receipt.view", "receipt.audit",
  "tithe.view", "tithe.manage",
  "member.view", "member.manage", "member.roles",
  "event.view", "event.manage",
  "report.view", "report.export",
  "reminder.view", "reminder.configure",
  "settings.view", "settings.manage",
] as const;

export type Permission = (typeof PERMISSIONS)[number];

const MEMBER: Permission[] = [
  "space.view",
  "contribution.view", "contribution.pay",
  "expense.view",
  "receipt.view",
  "tithe.view",
  "member.view",
  "event.view",
  "report.view",
  "reminder.view",
  "settings.view",
];

export const ROLE_PERMISSIONS: Record<Role, readonly Permission[]> = {
  member: MEMBER,
  admin: PERMISSIONS,
};

export function hasPermission(role: Role, permission: Permission) {
  return ROLE_PERMISSIONS[role].includes(permission);
}
