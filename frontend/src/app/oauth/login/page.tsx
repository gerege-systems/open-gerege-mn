// OIDC provider (RP-facing) login хуудас — Hydra нь browser-ыг энд login_challenge-
// тэй чиглүүлнэ. dan-ий ӨӨРИЙН дизайнаар (SigninShell + LoginForm: eID РД/QR +
// Google) нэвтрүүлж, буцаж ирэхэд challenge-ыг accept хийнэ. Дээр талд аль RP-ээс
// нэвтэрч буйг (client_name) харуулна.
import { redirect } from 'next/navigation';
import { getAccessToken } from '@gerege/ui-core/lib/session';
import { backendFetch } from '@gerege/ui-core/lib/api';
import LoginForm from '@gerege/ui-core/components/LoginForm';
import AcceptClient from './AcceptClient';
import { brand } from '@/brand.config';

export const dynamic = 'force-dynamic';

export default async function OAuthLoginPage(props: {
  searchParams: Promise<{ login_challenge?: string; glink?: string; gerror?: string }>;
}) {
  const sp = await props.searchParams;
  const challenge = sp.login_challenge;
  if (!challenge) redirect('/');
  const hasSession = !!(await getAccessToken());
  const next = `/oauth/login?login_challenge=${challenge}`;

  // Аль RP-ээс нэвтэрч буйг server талд авна (GetLogin — auth шаардахгүй).
  // `Enroll` нь superadmin бүртгэлийн урсгал эсэхийг backend бүртгэгдсэн
  // redirect_uri-аас гаргадаг (RP өөрөө зарлаж чадахгүй) — үнэн үед зөвхөн
  // Google-ээр нэвтрэх сонголтыг үзүүлнэ. Мэдээлэл ирээгүй бол ЭНГИЙН дэлгэц.
  let rpName = '';
  let enroll = false;
  const info = await backendFetch<{ ClientName?: string; ClientID?: string; Enroll?: boolean }>(
    `/provider/login?login_challenge=${encodeURIComponent(challenge)}`,
    { method: 'GET' },
  );
  if (info.ok && info.data) {
    rpName = info.data.ClientName || info.data.ClientID || '';
    enroll = info.data.Enroll === true;
  }

  return (
    <section className="signin-card" aria-labelledby="login-title">
      {rpName && (
        <div
          style={{
            marginBottom: 4,
            paddingBottom: 14,
            borderBottom: '1px solid var(--border)',
          }}
        >
          <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--fg)', lineHeight: 1.25 }}>
            {rpName}
          </div>
          <div style={{ fontSize: 13, color: 'var(--muted)', marginTop: 3 }}>
            {brand.name} — нэгдсэн нэвтрэлтээр нэвтрэх гэж байна
          </div>
        </div>
      )}
      {/* enroll урсгалд байгаа session-ыг ДАХИН ХЭРЭГЛЭХГҮЙ: бүртгэл нь тухайн
          Google хаягийн эзэмшлийг батлах ёстой тул (start нь `prompt=login`
          илгээдэг) шинээр нэвтрүүлнэ. */}
      {hasSession && !enroll ? (
        <AcceptClient challenge={challenge} />
      ) : (
        <LoginForm
          next={next}
          googleLink={sp.glink === '1'}
          googleError={!!sp.gerror}
          googleOnly={enroll}
        />
      )}
    </section>
  );
}
