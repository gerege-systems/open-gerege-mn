# البدء السريع

> من الاستنساخ إلى الدخول عبر eID على الحزمة الكاملة في خمس دقائق تقريبًا.

## المتطلّبات

| الأداة | الإصدار | ملاحظة |
|---|---|---|
| Go | 1.26+ | فقط إذا شغّلت الواجهة الخلفية مباشرةً |
| Node.js | 20+ | فقط إذا شغّلت الواجهة الأمامية مباشرةً |
| Docker + Compose | إصدار حديث | **موصى به** — الحزمة كاملةً بأمر واحد |
| PostgreSQL / Redis | 15+ / 7+ | غير مطلوبة عند استخدام Docker |

## 1. أسرع طريق — Docker Compose

```bash
git clone https://github.com/gerege-systems/open-gerege-mn.git
cd open-gerege-mn
docker compose up -d --build
```

يشغّل هذا `db` · `redis` · `migrate` (لمرّة واحدة) · `api` · `web`.
ثمّ افتح **<http://localhost:3000>**.

!!! note "تُطبَّق الترحيلات تلقائيًّا"
    تعمل خدمة `migrate` مع كلّ `up` وتتخطّى الترحيلات المطبَّقة سلفًا، فإعادة
    تشغيلها آمنة (غير تراكمية الأثر).

## 2. التشغيل يدويًّا (للتطوير)

=== "الواجهة الخلفية"

    ```bash
    cd backend
    cp .env.example .env
    # اضبط JWT_SECRET (32 محرفًا فأكثر) وقاعدة البيانات وRedis وبيانات اعتماد EID_*
    go run ./cmd/api          # ← http://localhost:8080
    ```

=== "الواجهة الأمامية"

    ```bash
    cd frontend
    cp .env.example .env.local     # BACKEND_URL=http://localhost:8080
    npm install
    npm run dev                    # ← http://localhost:3000
    ```

## 3. تسجيل الدخول

اختر **الدخول عبر eID** في الصفحة الرئيسية، ثمّ اسلك أحد ثلاثة مسارات:

- **رمز الاستجابة السريعة** — امسح رمز سطح المكتب بتطبيق eID على هاتفك.
- **App2App** — انتقل مباشرةً إلى تطبيق eID على الهاتف نفسه.
- **رقم السجل** — أدخله فيصل إشعار إلى التطبيق.

ولا يظهر الربط بحساب Google إلّا بعد ضبط بيانات اعتماده.

!!! tip "التجربة دون بيانات اعتماد eID"
    لن يعمل تسجيل الدخول ما دامت `EID_*` غير مضبوطة. وإذا كنت تريد فحص الواجهة
    والبنية فحسب، فإنّ اختبارات الوحدة في الواجهة الخلفية (`go test ./...`) تمرّ
    على المسارات عبر بديل FakeEID.

## 4. التحقّق

```bash
cd backend && go test ./...     # اختبارات الوحدة (بدائل، سريعة)
cd frontend && npm run build    # البناء + الفحص + التحقّق من الأنواع (كما في CI)
```

لتكرار كلّ بوّابات CI محلّيًّا:

```bash
cd backend && make pre-push     # الفحص + الاختبارات + انحراف swag + البناء
```

## إلى أين بعد ذلك

<div class="grid cards" markdown>

- :material-layers: **[البنية](architecture.md)** — الطبقات ومسار الاعتماديات
- :material-shield-key: **[المصادقة](authentication.md)** — مسارات eID + SSO
- :material-connection: **[تكامل التطبيقات](sso-integration.md)** — اجعل تطبيقك طرفًا معتمِدًا
- :material-cog: **[الإعدادات](configuration.md)** — مرجع متغيّرات البيئة

</div>
