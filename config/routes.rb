Rails.application.routes.draw do
  # OAuth 2.1 provider (Doorkeeper): /oauth/authorize, /oauth/token, etc.
  use_doorkeeper

  # Single-owner login (used by Doorkeeper's resource_owner_authenticator).
  get    "/owner/login",  to: "owner_sessions#new"
  post   "/owner/login",  to: "owner_sessions#create"
  delete "/owner/logout", to: "owner_sessions#destroy"

  # OAuth discovery metadata (RFC 9728 + RFC 8414). Bare + path-aware (/mcp) variants.
  get "/.well-known/oauth-protected-resource",      to: "oauth/metadata#protected_resource"
  get "/.well-known/oauth-protected-resource/mcp",  to: "oauth/metadata#protected_resource"
  get "/.well-known/oauth-authorization-server",     to: "oauth/metadata#authorization_server"
  get "/.well-known/oauth-authorization-server/mcp", to: "oauth/metadata#authorization_server"

  # Dynamic Client Registration (RFC 7591) — Doorkeeper lacks this.
  post "/oauth/register", to: "oauth/registration#create"

  # MCP over Streamable HTTP: Claude POSTs JSON-RPC here (guarded by the
  # McpDualAuth middleware). GET/DELETE are transport features we don't
  # support — answered with 405 per spec.
  post "/mcp", to: "mcp#handle"
  match "/mcp", to: "mcp#reject", via: [ :get, :delete ]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Native booking flow (Square Bookings API — Phase D2).
  get  "/book",              to: "bookings#show", as: :book
  get  "/book/availability", to: "bookings#availability"
  post "/book",              to: "bookings#create"

  # Defines the root path route ("/")
  root "pages#home"
end
