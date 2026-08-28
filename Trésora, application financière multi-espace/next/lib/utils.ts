import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatXOF(value: number) {
  return new Intl.NumberFormat("fr-CI", {
    style: "currency", currency: "XOF", maximumFractionDigits: 0,
  }).format(value);
}
