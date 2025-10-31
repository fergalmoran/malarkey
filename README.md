# Malarkey - Twitter Clone with Phoenix LiveView

A full-featured Twitter clone built with Elixir, Phoenix LiveView, and PostgreSQL with OAuth authentication.

## Features

### Authentication
✅ Email/Password registration and login
✅ OAuth providers (Google, GitHub, Twitter)
✅ Password reset functionality
✅ Email confirmation
✅ Session management with "Remember me" option
✅ Secure password hashing with Pbkdf2
✅ User settings management

### Social Features
✅ Post creation (280 character limit with character counter)
✅ Reposts and Quote Posts
✅ Replies/Comments (threaded conversations)
✅ Like/Unlike posts
✅ Follow/Unfollow users
✅ User profiles with bio, location, website
✅ Profile and header images
✅ Real-time updates via Phoenix PubSub

### User Interface
✅ Home timeline feed
✅ Post detail pages with replies
✅ User profile pages (posts, replies, media, likes tabs)
✅ Followers/Following lists
✅ Notifications page
✅ Explore/Search page
✅ Responsive design with Tailwind CSS
✅ Real-time post composer with character counter
✅ Interactive post actions (reply, repost, like, share)

### Coming Soon
🚧 Media upload (images, videos, GIFs)
🚧 Direct messaging
🚧 Hashtags and trending topics
🚧 User mentions (@username)
🚧 Bookmarks
🚧 Lists
🚧 Advanced search
🚧 Dark mode toggle

## Setup

### Prerequisites
- Erlang/OTP 28+
- Elixir 1.19+
- PostgreSQL 12+

### Installation

1. Install dependencies:
```bash
mix deps.get
```

2. Start PostgreSQL and create the database:
```bash
sudo systemctl start postgresql  # For systemd-based systems
mix ecto.create
mix ecto.migrate
```

3. (Optional) Set up OAuth provider credentials:
```bash
export GOOGLE_CLIENT_ID="your_google_client_id"
export GOOGLE_CLIENT_SECRET="your_google_client_secret"
export GITHUB_CLIENT_ID="your_github_client_id"
export GITHUB_CLIENT_SECRET="your_github_client_secret"
export TWITTER_CONSUMER_KEY="your_twitter_consumer_key"
export TWITTER_CONSUMER_SECRET="your_twitter_consumer_secret"
```

4. Start the Phoenix server:
```bash
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) in your browser.

## Database Schema

- **Users**: Authentication, profiles, statistics
- **Posts**: Content, media, relationships (replies, reposts, quotes)
- **Likes**: User-post favorites
- **Follows**: User relationships
- **OAuth Identities**: Third-party authentication
- **User Tokens**: Sessions, confirmations, password resets

## Architecture

Built with Phoenix best practices:
- Context-driven design (Accounts, Social)
- Ecto migrations with proper constraints
- UUID primary keys
- Counter caches for performance
- Real-time updates with PubSub
- Secure authentication with Ueberauth

## Next Steps

Complete the LiveView components:
- User registration/login/settings LiveViews
- Timeline with post composer
- Profile pages with tabs
- Post detail views with replies
- Implement Tailwind CSS styling with shadcn-inspired components

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
