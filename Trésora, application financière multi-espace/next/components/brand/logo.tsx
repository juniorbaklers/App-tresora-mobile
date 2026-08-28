import Image from "next/image";
import { cn } from "@/lib/utils";

/**
 * Trésora lockup.
 * The source asset is a square stacked lockup, so the horizontal lockup is
 * composed here: clean diamond mark (765×749) + text wordmark.
 */
export function Logo({
  variant = "full",
  className,
  priority,
}: {
  variant?: "full" | "mark" | "stacked";
  className?: string;
  priority?: boolean;
}) {
  if (variant === "stacked") {
    return (
      <Image
        src="/logo-full.png"
        alt="Trésora"
        width={1254}
        height={1254}
        priority={priority}
        className={cn("h-24 w-24 select-none object-contain", className)}
      />
    );
  }

  const mark = (
    <Image
      src="/logo-mark.png"
      alt={variant === "mark" ? "Trésora" : ""}
      width={765}
      height={749}
      priority={priority}
      className="h-full w-auto select-none"
    />
  );

  if (variant === "mark") {
    return <span className={cn("block h-11", className)}>{mark}</span>;
  }

  return (
    <span className={cn("flex h-10 items-center gap-3", className)}>
      {mark}
      <span className="text-2xl font-bold tracking-[-0.02em]">Trésora</span>
    </span>
  );
}
