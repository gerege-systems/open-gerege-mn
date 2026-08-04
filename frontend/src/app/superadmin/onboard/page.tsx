import React from 'react';
import SigninShell from '@gerege/ui-core/components/SigninShell';
import OnboardWizard from '@gerege/ui-core/components/superadmin/OnboardWizard';
import { pageTitle } from '@/brand.config';

export const dynamic = 'force-dynamic';

export const metadata = { title: pageTitle('Супер админ бүртгэл') };

// Нийтийн (auth-гүй) invite-gated superadmin онбординг wizard. Google callback
// нь энэ хуудсанд ?code= (Google), ?ssocode= (SSO) эсвэл ?gerror= (алдаа)
// буцаана. Хоёр IdP тусдаа параметртэй — wizard алийг нь дуудахаа мэдэх ёстой.
export default async function SuperadminOnboardPage(props: {
  searchParams: Promise<{ code?: string; ssocode?: string; gerror?: string }>;
}) {
  const searchParams = await props.searchParams;

  return (
    <SigninShell>
      <section className="signin-card" aria-labelledby="onboard-title">
        <OnboardWizard code={searchParams.code} ssocode={searchParams.ssocode} gerror={searchParams.gerror} />
      </section>
    </SigninShell>
  );
}
