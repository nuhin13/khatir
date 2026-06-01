import { Button } from "@/components/ui/button";
import { Card, CardDescription, CardTitle } from "@/components/ui/card";

/**
 * Placeholder login page. Real email + password + MFA flow is EPIC-11.
 * This is a non-functional shell so the route exists and renders.
 */
export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-cream p-s5">
      <Card className="w-full max-w-sm">
        <div className="mb-s5 text-center">
          <p className="font-title text-xl font-bold text-ink">Khatir Admin</p>
          <CardDescription>Sign in to the admin portal</CardDescription>
        </div>

        <CardTitle className="sr-only">Login</CardTitle>

        <form className="space-y-s4">
          <label className="block">
            <span className="mb-s1 block font-title text-sm text-ink2">
              Email
            </span>
            <input
              type="email"
              name="email"
              autoComplete="email"
              placeholder="you@khatir.com.bd"
              className="w-full rounded-sm border border-line bg-cream px-s3 py-s3 text-sm text-ink outline-none focus:border-sage"
            />
          </label>

          <label className="block">
            <span className="mb-s1 block font-title text-sm text-ink2">
              Password
            </span>
            <input
              type="password"
              name="password"
              autoComplete="current-password"
              placeholder="••••••••"
              className="w-full rounded-sm border border-line bg-cream px-s3 py-s3 text-sm text-ink outline-none focus:border-sage"
            />
          </label>

          <Button className="w-full" disabled>
            Sign in (MFA — coming in EPIC-11)
          </Button>
        </form>
      </Card>
    </main>
  );
}
