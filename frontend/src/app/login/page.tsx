// Gerege Systems Development Team & Claude AI, 2026
import React from 'react';
import SigninShell from '@gerege/ui-core/components/SigninShell';
import LoginPanel from '@gerege/ui-core/components/LoginPanel';
import { safeNext } from '@gerege/ui-core/lib/navigation';
import { fetchAuthMode } from '@gerege/ui-core/lib/authMode';
import { pageTitle } from '@/brand.config';

export const dynamic = 'force-dynamic';

export const metadata = { title: pageTitle('Нэвтрэх') };

// Нэвтрэх гадаргуу нь кодоор БИШ, backend-ийн AUTH_MODE-оор тодорхойлогдоно:
//
//   provider — платформ өөрөө нэвтрүүлнэ (eID РД/QR · нууц үг · Google карт);
//   client   — дээд SSO (SSO_ISSUER) руу шилжинэ, тэндээ нэвтэрч буцаж ирнэ
//              (OIDC RP урсгал). SSO callback амжилтгүй бол энд ?error=sso-тэй
//              буцаж, дахин оролдох боломж өгнө.
//
// Ингэснээр энэ хуудас нь SSO үйлчилгээ (sso.dgov.mn маягийн) болон түүний
// хэрэглэгч платформ хоёуланд НЭГ кодоор үйлчилнэ.
export default async function LoginPage(props: {
  searchParams: Promise<{
    next?: string;
    error?: string;
    notice?: string;
    glink?: string;
    gerror?: string;
    mfa?: string;
  }>;
}) {
  const searchParams = await props.searchParams;
  const next = safeNext(searchParams.next);
  const auth = await fetchAuthMode();

  return (
    <SigninShell>
      <section className="signin-card" aria-labelledby="login-title">
        <LoginPanel
          auth={auth}
          next={next}
          notice={searchParams.notice}
          googleLink={searchParams.glink === '1'}
          googleError={!!searchParams.gerror}
          mfaGate={searchParams.mfa === '1'}
          ssoFailed={searchParams.error === 'sso'}
        />
      </section>
    </SigninShell>
  );
}
