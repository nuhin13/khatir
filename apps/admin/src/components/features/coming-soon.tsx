import { Construction } from "lucide-react";
import { Card } from "@/components/ui/card";

export function ComingSoon({ title }: { title: string }) {
  return (
    <div className="space-y-s5">
      <h1 className="font-title text-2xl font-bold text-ink">{title}</h1>
      <Card className="flex flex-col items-center gap-s3 py-s8 text-center">
        <Construction size={40} className="text-butterDk" aria-hidden />
        <p className="font-title text-base font-semibold text-ink">
          Coming soon
        </p>
        <p className="max-w-md text-sm text-muted">
          This admin module has not been built yet. It will arrive in a later
          EPIC.
        </p>
      </Card>
    </div>
  );
}
