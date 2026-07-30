# تكامل التطبيقات (Gerege SSO / طرف معتمِد OIDC)

اربط تطبيقك كطرف معتمِد لدى **Gerege SSO (sso.gerege.mn)**. حين ينقر المستخدم
على «تسجيل الدخول»، يُحوَّل إلى sso.gerege.mn، ويصادِق عبر eID، ثمّ يعود إلى
تطبيقك.

## 1. سجّل تطبيقك كعميل طرف معتمِد

طريقتان:

=== "واجهة الإدارة"

    من **الإدارة ← التطبيقات ← تطبيق جديد**، أدخل الاسم وعنوان إعادة التوجيه
    والوسم ثمّ احفظ. وامنح خدمات eID التي تحتاجها (مثل eid-proxy) عبر خانات
    الاختيار. ستحصل على `client_id` و`client_secret`.

=== "أداة سطر الأوامر"

    على الخادم، يضبط `register-rp.sh` **كلًّا من** عنوان إعادة التوجيه عند
    الدخول وعنوان ما بعد الخروج بشكل صحيح (حتى لا يفشل تسجيل الخروج):

    ```bash
    cd /srv/sso-dgov-mn
    ./scripts/register-rp.sh "تطبيقي" https://myapp.dgov.mn
    # ← يطبع client_id و client_secret
    #   redirect_uri            = https://myapp.dgov.mn/sso/callback
    #   post_logout_redirect_uri= https://myapp.dgov.mn/
    ```

## 2. إعداد التطبيق

إذا كان تطبيقك مبنيًّا على هذا القالب، اضبط في `backend.env`:

```env
SSO_ISSUER=https://sso.gerege.mn
SSO_CLIENT_ID=<client_id>
SSO_CLIENT_SECRET=<client_secret>
SSO_REDIRECT_URI=https://myapp.dgov.mn/sso/callback
SSO_SCOPE=openid profile email
```

## 3. مسار تسجيل الدخول

1. ينقر المستخدم على **«الدخول عبر Gerege SSO»** ← `/api/auth/sso/start`.
2. ينشئ `/sso/start` في الواجهة الخلفية حالة (في Redis) ويبني عنوان التخويل
   `sso.gerege.mn/oauth2/auth`، ثمّ يُحوَّل المتصفّح إليه.
3. يصادِق المستخدم عبر eID على sso.gerege.mn.
4. يعيد sso.gerege.mn التوجيه إلى
   `https://myapp.dgov.mn/sso/callback?code&state`.
5. يستبدل `/sso/callback` الرمزَ بالرموز المميّزة، ويحدّث سجلّ المواطن حسب
   `sso_sub`، ثمّ يصدر جلسة التطبيق الخاصّة (JWT).

## 4. تسجيل الخروج

يحوّل الخروجُ الذي يبدأه الطرف المعتمِد إلى
`sso.gerege.mn/oauth2/sessions/logout` مع `id_token_hint` و
`post_logout_redirect_uri`. ويجب أن يكون عنوان ما بعد الخروج **مسجَّلًا على
العميل** (ويضبطه `register-rp.sh` تلقائيًّا).

!!! warning "سجّل عنوان ما بعد الخروج"
    إذا سُجِّل التطبيق بعنوان دخول فقط، يفشل تسجيل الخروج برسالة
    *«post_logout_redirect_uri is not whitelisted»*. ويضبط `register-rp.sh`
    وواجهةُ الإدارة العنوانين معًا، فلا يقع هذا الخطأ.

## منح الخدمات الإضافية

إلى جانب تسجيل الدخول، إذا احتاج تطبيقك إلى خدمات SSO **الإضافية** (مثل وكيل
eID)، يمنح المشرف تلك الخدمة للتطبيق. انظر
[وكيل خدمات eID](eid-services.md) و[بوّابة API](api-gateway.md).
