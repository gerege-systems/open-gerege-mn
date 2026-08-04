import React from 'react';
import { redirect } from 'next/navigation';
import PageHead from '@gerege/ui-core/components/PageHead';
import ModulesManager from '@gerege/ui-core/components/admin/ModulesManager';
import { fetchMe, fetchMyPermissions } from '@gerege/ui-core/lib/api';

export const dynamic = 'force-dynamic';
export const metadata = { title: 'Модулиуд — Супер админ' };

export default async function AdminModulesPage() {
  const me = await fetchMe();
  if (!me) redirect('/login?next=/admin/modules');
  // Модуль асаах/унтраах нь платформын бүтцийг өөрчилдөг тул зөвхөн
  // супер админ. Backend талдаа мөн шалгагдана — энэ нь зөвхөн UX.
  const perms = await fetchMyPermissions();
  if (!perms.includes('settings.manage')) redirect('/');

  return (
    <>
      <PageHead eyebrowKey="sys.superadmin" titleKey="modules.title" subKey="modules.sub" />
      <ModulesManager />
    </>
  );
}
