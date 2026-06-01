import { UserCircle } from "lucide-react";

export function Topbar() {
  return (
    <header className="flex h-16 items-center justify-between border-b border-line bg-card px-s6">
      <div className="font-title text-sm text-muted">Admin Portal</div>
      <div className="flex items-center gap-s3">
        <span className="font-title text-sm text-ink2">Signed in</span>
        <UserCircle size={28} className="text-sage" aria-hidden />
      </div>
    </header>
  );
}
