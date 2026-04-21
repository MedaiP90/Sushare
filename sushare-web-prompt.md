# AI Coding Prompt: Sushare — Web Platform

> **Target stack:** Node.js + Express · Vue 3 · MongoDB  
> **Purpose:** Guide an AI coding assistant to implement the full platform from scratch.  
> **Language:** All code, comments, and documentation must be written in **English**.

---

## 1. Project Overview

Build **Sushare** — a web platform that lets groups of friends collectively compose an order before visiting an all-you-can-eat sushi restaurant. Users join a shared session, each builds their personal sub-order, and the platform merges everything into a single aggregated order. After the order is sent, each person tracks what has arrived at the table.

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Database | MongoDB (via Mongoose ODM) |
| Backend | Node.js 20+ with Express 5 |
| Frontend | Vue 3 (Composition API, `<script setup>`) with Vite |
| Auth | JWT (access + refresh tokens) + Passport.js (Google OAuth 2.0, Apple Sign-In) |
| Real-time | Socket.IO (session live updates) |
| Image handling | Multer (upload) + Sharp (resize/optimize) |
| AI menu extraction | Anthropic Claude API (`claude-sonnet-4-20250514`) |
| Styling | CSS custom properties (no utility frameworks); Google Fonts |

---

## 3. Code Quality Requirements

Apply these rules **consistently across every file**:

### 3.1 OOP Principles (EPAM reference)
- **Single Responsibility:** every class/module does exactly one thing.
- **Open/Closed:** extend behaviour via new modules, not by modifying existing ones.
- **Liskov Substitution:** subclasses must be usable wherever the parent is expected.
- **Interface Segregation:** small, focused interfaces — no fat controllers.
- **Dependency Inversion:** high-level modules depend on abstractions, not concrete implementations (use dependency injection via constructor parameters or a simple DI container).

### 3.2 Indentation & Readability
- Maximum **2 levels of block nesting** inside any function body.
- Use **early returns / guard clauses** to avoid deep else branches.
- Extract any logic beyond 2 levels into a clearly named helper function.

### 3.3 Comments
- Every file starts with a **JSDoc module comment** explaining its responsibility.
- Every exported class/function has a **JSDoc block** (purpose, params, return value).
- Inline comments explain the *why*, not the *what*.
- Use `// TODO:` and `// FIXME:` tags where appropriate.

### 3.4 General
- All async functions use `async/await`; avoid raw `.then()` chains.
- All errors are thrown as custom `AppError` subclasses (see §6.1).
- No `any` types if TypeScript is introduced in the future (design for easy migration).
- Environment variables managed via `dotenv`; never hard-code secrets.

---

## 4. Repository Structure

```
sushare/
├── backend/
│   ├── src/
│   │   ├── config/           # DB, passport, env validation
│   │   ├── errors/           # AppError hierarchy
│   │   ├── middleware/        # auth, error handler, upload, validation
│   │   ├── models/            # Mongoose models (one file per model)
│   │   ├── repositories/      # Data-access layer (one per model)
│   │   ├── services/          # Business logic (one per domain)
│   │   ├── controllers/       # HTTP handlers (thin, delegate to services)
│   │   ├── routes/            # Express routers (one per domain)
│   │   ├── sockets/           # Socket.IO event handlers
│   │   ├── utils/             # Pure utility functions
│   │   └── app.js             # Express app factory
│   ├── server.js              # Entry point (binds HTTP + Socket.IO)
│   └── package.json
│
├── frontend/
│   ├── src/
│   │   ├── assets/            # Fonts, global CSS variables
│   │   ├── components/        # Reusable Vue components
│   │   ├── composables/       # Reusable Composition API hooks
│   │   ├── layouts/           # Page shell layouts
│   │   ├── pages/             # Route-level views
│   │   ├── router/            # Vue Router configuration
│   │   ├── stores/            # Pinia stores (one per domain)
│   │   ├── services/          # API client wrappers
│   │   └── main.js
│   ├── index.html
│   └── package.json
│
└── docker-compose.yml         # MongoDB + app services for local dev
```

---

## 5. Data Models

Implement each model in its own file under `backend/src/models/`.  
Every model must include `createdAt` / `updatedAt` via Mongoose `timestamps: true`.

### 5.1 User
```
User {
  _id, username (unique, trimmed, 3-30 chars),
  email (unique, lowercase), passwordHash (nullable for OAuth users),
  googleId (nullable), appleId (nullable),
  firstName (trimmed, max 50 chars),
  lastName (trimmed, max 50 chars),
  profilePictureUrl (nullable),     // URL of uploaded profile photo
  friends: [ObjectId → User],
  friendRequests: [{ from: ObjectId, status: 'pending'|'accepted'|'rejected' }],
  savedOrders: [ObjectId → SavedOrder],
  createdAt, updatedAt
}
```

### 5.2 Restaurant
```
Restaurant {
  _id, name, address, coverImageUrl,
  menu: [MenuItem],
  createdBy: ObjectId → User,
  createdAt, updatedAt
}

MenuItem {
  _id, name, category, description, imageUrl,
  addedBy: ObjectId → User   // tracks who contributed this item
}
```

### 5.3 Session
```
Session {
  _id, name,
  restaurant: ObjectId → Restaurant,
  createdBy: ObjectId → User,
  participants: [ObjectId → User],
  status: 'open' | 'sent' | 'closed',
  mainOrder: Order,            // aggregated order built at send time
  additionalOrders: [Order],   // post-send supplementary orders
  createdAt, updatedAt
}

Order {
  _id, label,               // e.g. "Main" or "Round 2"
  items: [OrderItem],
  sentAt: Date (nullable)
}

OrderItem {
  menuItemId: ObjectId → MenuItem,
  name,                     // denormalized snapshot
  quantity: Number,
  contributors: [ObjectId → User]  // who ordered this dish
}
```

### 5.4 PersonalSubOrder
```
PersonalSubOrder {
  _id,
  session: ObjectId → Session,
  user: ObjectId → User,
  items: [{ menuItemId, name, quantity }],
  checklist: [{ menuItemId, name, quantity, arrivedCount: Number }],
  locked: Boolean,          // true once session is sent
  createdAt, updatedAt
}
```

### 5.5 SavedOrder
```
SavedOrder {
  _id,
  user: ObjectId → User,
  restaurant: ObjectId → Restaurant,
  items: [{ menuItemId, name, quantity }],
  label,
  createdAt, updatedAt
}
```

---

## 6. Backend Implementation

### 6.1 Error Hierarchy (`backend/src/errors/`)

```js
/**
 * @module errors
 * Base application error class and domain-specific subclasses.
 */

class AppError extends Error {
  constructor(message, statusCode) { ... }
}

class NotFoundError extends AppError { constructor(msg) { super(msg, 404) } }
class UnauthorizedError extends AppError { constructor(msg) { super(msg, 401) } }
class ForbiddenError extends AppError { constructor(msg) { super(msg, 403) } }
class ValidationError extends AppError { constructor(msg) { super(msg, 422) } }
class ConflictError extends AppError { constructor(msg) { super(msg, 409) } }
```

### 6.2 Repository Pattern

Each repository class wraps Mongoose calls. No business logic lives here.

```js
/**
 * @class UserRepository
 * @description Data-access layer for User documents. 
 */
class UserRepository {
  async findById(id) { ... }
  async findByEmail(email) { ... }
  async findByUsername(username) { ... }
  async searchByUsername(query, excludeId) { ... }  // for friend search
  async create(data) { ... }
  async update(id, data) { ... }
}
```

Create equivalent repositories for: `RestaurantRepository`, `SessionRepository`, `PersonalSubOrderRepository`, `SavedOrderRepository`.

### 6.3 Service Layer

Services contain all business logic and depend on repositories via constructor injection.

#### `AuthService`
- `register({ username, email, password })` → creates user, returns tokens
- `login({ email, password })` → validates credentials, returns tokens
- `loginWithGoogle(profile)` → upserts user from Google profile, returns tokens
- `loginWithApple(profile)` → upserts user from Apple profile, returns tokens
- `refreshToken(token)` → validates refresh token, issues new access token
- `generateTokenPair(userId)` → private helper, creates JWT access + refresh tokens

#### `UserService`
- `getProfile(userId)` → returns user without sensitive fields
- `updateProfile(userId, { firstName, lastName, username })` → validates username uniqueness, updates fields
- `updateProfilePicture(userId, imageBuffer)` → resizes image to 256 × 256 px (Sharp), saves to disk/CDN, updates `profilePictureUrl`
- `deleteProfilePicture(userId)` → removes file, sets `profilePictureUrl` to null
- `searchUsers(query, requestingUserId)` → returns matching users (by username, firstName, lastName) excluding self
- `sendFriendRequest(fromId, toId)` → creates request, emits socket event
- `respondFriendRequest(userId, requestId, action)` → accepts/rejects
- `getFriends(userId)` → returns friends list with basic profile data

#### `RestaurantService`
- `create(data, creatorId)` → creates restaurant
- `getById(id)` → populated restaurant with menu
- `addMenuItem(restaurantId, item, userId)` → adds item to menu if not duplicate
- `extractMenuFromImage(imageBuffer, restaurantId, userId)` → calls Claude API (see §6.5), parses response, calls `addMenuItem` for each extracted item
- `list(query)` → paginated list

#### `SessionService`
- `create(data, creatorId)` → creates session, adds creator as first participant
- `addParticipant(sessionId, userId, requestingUserId)` → only creator can add; emits socket event
- `getById(id, userId)` → session with populated participants; validates user is a participant
- `upsertPersonalSubOrder(sessionId, userId, items)` → creates/updates the user's sub-order (only while status is `'open'`)
- `sendOrder(sessionId, userId)` → aggregates all sub-orders (see §6.4), sets status `'sent'`, locks sub-orders
- `addAdditionalOrder(sessionId, userId, items)` → appends a new `Order` to `additionalOrders` (only when status is `'sent'`)
- `updateChecklist(sessionId, userId, updates)` → updates `arrivedCount` fields in user's `PersonalSubOrder`
- `getPersonalSubOrder(sessionId, userId)` → returns the user's sub-order

#### `SavedOrderService`
- `save(userId, restaurantId, items, label)` → creates SavedOrder
- `list(userId, restaurantId)` → returns user's saved orders for a restaurant
- `delete(userId, savedOrderId)` → deletes if owner matches

### 6.4 Order Aggregation Algorithm

Implement as a pure utility function in `backend/src/utils/aggregateOrders.js`:

```js
/**
 * Merges multiple personal sub-orders into a single aggregated order.
 * Dishes with the same menuItemId are combined; their quantities are summed
 * and the contributor user IDs are collected.
 *
 * @param {PersonalSubOrder[]} subOrders - Array of personal sub-order documents
 * @returns {OrderItem[]} Aggregated list of order items
 */
function aggregateOrders(subOrders) {
  const itemMap = new Map(); // key: menuItemId.toString()

  for (const subOrder of subOrders) {
    for (const item of subOrder.items) {
      const key = item.menuItemId.toString();

      if (!itemMap.has(key)) {
        itemMap.set(key, {
          menuItemId: item.menuItemId,
          name: item.name,
          quantity: 0,
          contributors: [],
        });
      }

      const aggregate = itemMap.get(key);
      aggregate.quantity += item.quantity;
      aggregate.contributors.push(subOrder.user);
    }
  }

  return Array.from(itemMap.values());
}
```

### 6.5 AI Menu Extraction

In `RestaurantService.extractMenuFromImage`:

1. Accept `imageBuffer` (from Multer memory storage).
2. Convert buffer to base64.
3. Call the Anthropic API with the image and prompt:

```js
const prompt = `
You are a menu digitisation assistant.
Analyse the provided restaurant menu image.
Return ONLY a valid JSON array — no markdown fences, no preamble.
Each element must follow this schema:
{ "name": string, "category": string, "description": string }

Rules:
- "name" is the dish name exactly as printed.
- "category" groups similar dishes (e.g. "Nigiri", "Maki", "Temaki", "Dessert").
- "description" is a short English sentence if visible; otherwise an empty string.
- Do not invent dishes not present in the image.
`;
```

4. Parse the JSON response.
5. For each extracted item, call `addMenuItem` (duplicates are silently skipped via a case-insensitive name check).
6. Return the list of newly added items.

### 6.6 API Routes

Prefix all routes with `/api/v1`.

```
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
GET    /auth/google          (Passport redirect)
GET    /auth/google/callback
GET    /auth/apple           (Passport redirect)
GET    /auth/apple/callback

GET    /users/me
PATCH  /users/me                          (update username, firstName, lastName)
POST   /users/me/picture                  (multipart/form-data — upload profile photo)
DELETE /users/me/picture
GET    /users/search?q=
POST   /users/friends/request/:targetId
PATCH  /users/friends/request/:requestId
GET    /users/friends

GET    /restaurants
POST   /restaurants
GET    /restaurants/:id
POST   /restaurants/:id/menu/items
POST   /restaurants/:id/menu/scan     (multipart/form-data with image)

GET    /sessions
POST   /sessions
GET    /sessions/:id
POST   /sessions/:id/participants
GET    /sessions/:id/sub-order
PUT    /sessions/:id/sub-order
POST   /sessions/:id/send
POST   /sessions/:id/additional-orders
PATCH  /sessions/:id/checklist

GET    /restaurants/:restaurantId/saved-orders
POST   /restaurants/:restaurantId/saved-orders
DELETE /saved-orders/:savedOrderId
```

### 6.7 Authentication Middleware

```js
/**
 * Express middleware that validates the Bearer JWT in the Authorization header.
 * Attaches the decoded user payload to `req.user`.
 * Throws UnauthorizedError on missing or invalid token.
 */
async function requireAuth(req, res, next) { ... }
```

### 6.8 Socket.IO Events

Namespace: `/sessions`

| Event (server emits) | Payload | Trigger |
|---|---|---|
| `participant:joined` | `{ userId, displayName }` | participant added to session |
| `suborder:updated` | `{ userId }` | user updates personal sub-order |
| `session:sent` | `{ aggregatedOrder }` | session order is sent |
| `session:additionalOrder` | `{ order }` | additional order added |
| `checklist:updated` | `{ userId, updates }` | user updates arrival checklist |

Each socket connection must authenticate with a JWT (passed as a handshake `auth.token`).

---

## 7. Frontend Implementation

### 7.1 Design System

Define all design tokens in `frontend/src/assets/global.css` using CSS custom properties:

```css
/* Typography — elegant serif for headings, clean readable serif for body */
@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;1,400&family=Lora:wght@400;500&display=swap');

:root {
  /* Colour palette — dark ink on warm ivory */
  --color-bg:          #FAF8F4;
  --color-surface:     #FFFFFF;
  --color-ink:         #1A1410;
  --color-ink-muted:   #6B5F52;
  --color-accent:      #C0392B;       /* deep red — sushi red */
  --color-accent-soft: #F5E6E4;
  --color-border:      #E8E0D5;
  --color-success:     #2E7D5E;
  --color-warning:     #B8860B;

  /* Typography */
  --font-display: 'Cormorant Garamond', Georgia, serif;
  --font-body:    'Lora', Georgia, serif;

  --text-xs:   0.75rem;
  --text-sm:   0.875rem;
  --text-base: 1rem;
  --text-lg:   1.125rem;
  --text-xl:   1.375rem;
  --text-2xl:  1.75rem;
  --text-3xl:  2.5rem;
  --text-4xl:  3.5rem;

  /* Spacing scale */
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;

  /* Radii */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 16px;
  --radius-full: 9999px;

  /* Shadows */
  --shadow-sm: 0 1px 3px rgba(26,20,16,.08);
  --shadow-md: 0 4px 16px rgba(26,20,16,.10);
  --shadow-lg: 0 12px 40px rgba(26,20,16,.14);

  /* Transitions */
  --transition-fast:   150ms ease;
  --transition-normal: 250ms ease;
}
```

### 7.2 Reusable Components

Build each as a single-file Vue component (`.vue`) with `<script setup>`, typed props via `defineProps`.

| Component | Description |
|---|---|
| `BaseButton.vue` | variant: `primary`, `secondary`, `ghost`, `danger`; loading state |
| `BaseInput.vue` | label, error message, prefix/suffix slots |
| `BaseModal.vue` | teleports to `<body>`, focus trap, keyboard close |
| `BaseToast.vue` | success / error / info toasts via composable |
| `MenuItemCard.vue` | dish name, category, + / − quantity stepper |
| `OrderSummaryPanel.vue` | aggregated order list with contributor avatars |
| `ChecklistItem.vue` | single dish arrival tracker with +/- arrived counter |
| `UserAvatar.vue` | circular avatar: shows `profilePictureUrl` photo if set, falls back to initials (firstName[0] + lastName[0]) on coloured background |
| `FriendCard.vue` | user card with add/pending/friends state |
| `RestaurantCard.vue` | restaurant cover + name |
| `SessionCard.vue` | session name, status badge, participant avatars |
| `ScanMenuButton.vue` | file input that triggers image upload + loading state |

### 7.3 Pinia Stores

#### `useAuthStore`
```js
state: { user, accessToken, refreshToken, isLoading }
actions: register, login, loginWithGoogle, loginWithApple, logout, refreshSession
```

#### `useSessionStore`
```js
state: { currentSession, personalSubOrder, participants, isLoading }
actions: loadSession, updateSubOrder, sendOrder, addAdditionalOrder, updateChecklist
getters: aggregatedOrder, myChecklist
```

#### `useRestaurantStore`
```js
state: { restaurants, currentRestaurant, isLoading }
actions: loadRestaurants, loadRestaurant, addMenuItem, scanMenu
```

#### `useFriendsStore`
```js
state: { friends, requests, searchResults, isLoading }
actions: searchUsers, sendRequest, respondRequest, loadFriends
```

### 7.4 Pages / Routes

```
/                          → LandingPage
/login                     → LoginPage
/register                  → RegisterPage

/app/                      → AppLayout (requires auth)
  dashboard                → DashboardPage    (active sessions + restaurants)
  restaurants              → RestaurantsPage
  restaurants/:id          → RestaurantPage   (menu browser + scan button)
  sessions/new             → NewSessionPage
  sessions/:id             → SessionPage      (main session view)
  sessions/:id/order       → OrderPage        (personal sub-order editor)
  sessions/:id/merged      → MergedOrderPage  (aggregated view, post-send)
  sessions/:id/checklist   → ChecklistPage    (arrival tracker)
  friends                  → FriendsPage
  profile                  → ProfilePage
```

### 7.5 SessionPage Flow

Implement the session flow as a state machine driven by `session.status`:

| Status | UI shown |
|---|---|
| `open` | Sub-order editor + participant list + "Send Order" button (creator only) |
| `sent` | Merged order view + "Add Round" button + personal checklist |
| `closed` | Read-only order history |

### 7.6 API Service Layer

Create `frontend/src/services/api.js`:
- Axios instance with base URL from `import.meta.env.VITE_API_URL`.
- Request interceptor attaches `Authorization: Bearer <accessToken>`.
- Response interceptor catches 401, calls `refreshSession`, retries once, then logs out.

Domain wrappers:
- `authApi` — register, login, refresh, OAuth redirects
- `usersApi` — me, search, friends CRUD
- `restaurantsApi` — list, get, addItem, scanMenu
- `sessionsApi` — list, get, create, subOrder CRUD, send, additionalOrders, checklist
- `savedOrdersApi` — list, save, delete

### 7.7 Socket.IO Composable

`frontend/src/composables/useSessionSocket.js`:

```js
/**
 * @composable useSessionSocket
 * Manages a Socket.IO connection scoped to a single session.
 * Automatically connects on mount, disconnects on unmount.
 *
 * @param {string} sessionId - The session to subscribe to
 * @returns {{ isConnected, lastEvent }}
 */
export function useSessionSocket(sessionId) { ... }
```

On receiving events, update the relevant Pinia store slices directly.

---

## 8. Authentication Flows

### 8.1 Email / Password
- Register: POST `/auth/register` → store tokens in `localStorage` + Pinia.
- Login: POST `/auth/login` → same.
- The access token expires in 15 minutes; the refresh token in 7 days.
- On app boot, `useAuthStore` reads tokens from `localStorage`, calls `/users/me`; on 401 it attempts refresh, then redirects to `/login`.

### 8.2 Google OAuth
- Frontend link: `<a href="/api/v1/auth/google">` — navigates the browser to the backend.
- Backend Passport callback redirects to `{FRONTEND_URL}/auth/callback?accessToken=...&refreshToken=...`.
- Frontend `/auth/callback` page reads query params, stores tokens, redirects to `/app/dashboard`.

### 8.3 Apple Sign-In
- Same pattern as Google. Use `passport-apple` package.
- Note: Apple requires HTTPS and a registered domain in production; document this in `README.md`.

---

## 9. Menu Scanning Flow

1. User opens a `RestaurantPage` and taps **"Scan Menu"**.
2. `ScanMenuButton.vue` opens a file picker (accept: `image/*`).
3. Selected image is POST-ed as `multipart/form-data` to `/api/v1/restaurants/:id/menu/scan`.
4. Backend `RestaurantService.extractMenuFromImage` calls the Claude API.
5. On success, the restaurant's menu is updated in the DB and the response contains newly added items.
6. The frontend `useRestaurantStore` merges new items into `currentRestaurant.menu`.
7. Display a toast listing how many new dishes were added.

---

## 10. Environment Variables

### Backend (`.env`)
```
PORT=3000
MONGODB_URI=mongodb://localhost:27017/sushare
JWT_SECRET=<long-random-string>
JWT_REFRESH_SECRET=<another-long-random-string>
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
APPLE_CLIENT_ID=
APPLE_TEAM_ID=
APPLE_KEY_ID=
APPLE_PRIVATE_KEY_PATH=
ANTHROPIC_API_KEY=
FRONTEND_URL=http://localhost:5173
```

### Frontend (`.env`)
```
VITE_API_URL=http://localhost:3000/api/v1
VITE_SOCKET_URL=http://localhost:3000
```

---

## 11. Error Handling

### Backend
- A single `errorHandler` Express middleware catches all thrown `AppError` instances and formats them as `{ error: { message, code } }`.
- Unhandled Mongoose `ValidationError` is mapped to `ValidationError (422)`.
- Mongoose `MongoServerError` code 11000 (duplicate key) is mapped to `ConflictError (409)`.

### Frontend
- All API errors are caught in the Axios interceptor.
- Domain errors are surfaced via the `useToast` composable.
- Form-level validation errors are mapped to individual field error messages.

---

## 12. Implementation Order

Implement features in this sequence to enable early testing at each step:

1. **Project scaffolding** — monorepo structure, Docker Compose for MongoDB, `.env` setup.
2. **Auth** — User model, AuthService, JWT middleware, login/register routes + Vue pages.
3. **Restaurants** — Restaurant model + CRUD routes + Vue pages (without scan).
4. **Sessions (basic)** — Session model, create/join, personal sub-order editor.
5. **Order aggregation** — `aggregateOrders` util, send-order flow, merged view.
6. **Real-time** — Socket.IO integration for live session updates.
7. **Checklist** — post-send arrival tracking UI.
8. **Friends** — friend request flow, user search.
9. **Additional rounds** — supplementary post-send order lists.
10. **Menu scanning** — Multer upload, Claude API integration.
11. **Saved orders** — save/load personal order presets.
12. **OAuth** — Google + Apple sign-in.
13. **Polish** — loading states, error boundaries, mobile responsiveness.

---

## 13. README Requirements

Generate a `README.md` that includes:
- Project description and feature list.
- Prerequisites (Node 20+, MongoDB 7+, Anthropic API key).
- Local setup steps (`npm install`, environment variables, `docker-compose up`).
- Apple Sign-In production requirements (HTTPS, domain registration).
- Architecture diagram (ASCII or Mermaid).
- API route table (auto-generated from routes).

---

## 14. Additional Notes for the AI Coding Assistant

- Do **not** use deprecated Mongoose APIs (`Model.findOne` callbacks, etc.); always use `async/await`.
- Do **not** import entire libraries when only specific parts are needed (tree-shaking).
- Do **not** use `var`; use `const` by default, `let` only when reassignment is necessary.
- Keep Vue components focused: if a component exceeds ~150 lines, extract sub-components.
- Use Pinia `$patch` for bulk state updates.
- All monetary/quantity arithmetic that loops over arrays should use `Array.reduce`, not manual loops with mutable accumulators outside the function.
- For the session page, use Vue's `computed` to derive UI state from `session.status` — do not duplicate status checks across the template.
- Socket.IO listeners must be registered in `onMounted` and cleaned up in `onUnmounted`.
- Validate all ObjectId path parameters in Express with a middleware (`mongoose.isValidObjectId`), returning 400 before any DB call.
