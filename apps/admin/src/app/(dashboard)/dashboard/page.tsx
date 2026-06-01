import { Card, CardDescription, CardTitle } from "@/components/ui/card";
import { Chip } from "@/components/ui/chip";

const KPIS = [
  { label: "Total landlords", value: "—" },
  { label: "Active tenants", value: "—" },
  { label: "Rent collected (BDT)", value: "—" },
  { label: "Open tickets", value: "—" },
];

/**
 * Placeholder dashboard. Real aggregations land with the dashboard module.
 * Shows the KPI shell plus an empty-state card (loading/empty states present).
 */
export default function DashboardPage() {
  return (
    <div className="space-y-s6">
      <div className="flex items-center gap-s3">
        <h1 className="font-title text-2xl font-bold text-ink">Dashboard</h1>
        <Chip tone="butter">Placeholder</Chip>
      </div>

      <section className="grid grid-cols-1 gap-s4 sm:grid-cols-2 lg:grid-cols-4">
        {KPIS.map((kpi) => (
          <Card key={kpi.label}>
            <CardDescription>{kpi.label}</CardDescription>
            <p className="mt-s2 font-title text-3xl font-bold text-ink">
              {kpi.value}
            </p>
          </Card>
        ))}
      </section>

      <Card className="flex flex-col items-center gap-s2 py-s8 text-center">
        <CardTitle>No data yet</CardTitle>
        <CardDescription>
          Platform metrics will appear here once the dashboard module is wired
          to the API.
        </CardDescription>
      </Card>
    </div>
  );
}
