// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Theme handling
const applyTheme = (theme) => {
  if (theme === 'system') {
    const isDarkMode = window.matchMedia('(prefers-color-scheme: dark)').matches
    document.documentElement.classList.toggle('dark', isDarkMode)
  } else if (theme === 'dark') {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
  
  // Update button states
  document.querySelectorAll('[data-theme]').forEach(btn => {
    if (btn.dataset.theme === theme) {
      btn.classList.remove('border-input')
      btn.classList.add('border-primary', 'bg-accent')
    } else {
      btn.classList.remove('border-primary', 'bg-accent')
      btn.classList.add('border-input')
    }
  })
}

const initTheme = () => {
  const theme = localStorage.getItem('theme') || 'system'
  applyTheme(theme)
  
  // Listen for system theme changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (localStorage.getItem('theme') === 'system') {
      document.documentElement.classList.toggle('dark', e.matches)
    }
  })
}

// Initialize theme on page load
initTheme()

// Hooks for theme management and media upload
let Hooks = {}
Hooks.ThemeSelector = {
  mounted() {
    this.el.addEventListener("click", () => {
      const theme = this.el.dataset.theme
      localStorage.setItem('theme', theme)
      applyTheme(theme)
    })
  }
}

Hooks.PasteImage = {
  mounted() {
    console.log("PasteImage hook mounted on element:", this.el.id)
    
    // Auto-focus if this is a reply textarea
    if (this.el.id === "reply-textarea") {
      this.el.focus()
    }
    
    this.el.addEventListener("paste", (e) => {
      console.log("Paste event detected on textarea:", this.el.id)
      
      const clipboardData = e.clipboardData || e.originalEvent?.clipboardData || window.clipboardData
      
      if (!clipboardData) {
        console.log("No clipboard data available")
        return
      }
      
      const items = clipboardData.items
      if (!items) {
        console.log("No clipboard items")
        return
      }
      
      console.log("Clipboard items:", items.length)
      
      for (let i = 0; i < items.length; i++) {
        const item = items[i]
        console.log("Item type:", item.type, item.kind)
        
        if (item.kind === 'file' && item.type.indexOf("image") !== -1) {
          e.preventDefault()
          console.log("Image found in clipboard")
          
          const blob = item.getAsFile()
          if (!blob) {
            console.log("Failed to get file from clipboard item")
            continue
          }
          
          const reader = new FileReader()
          
          reader.onload = (event) => {
            console.log("Image loaded, sending to server from textarea:", this.el.id)
            this.pushEvent("paste_image", {
              data: event.target.result,
              type: blob.type,
              textarea_id: this.el.id
            })
          }
          
          reader.onerror = (error) => {
            console.error("FileReader error:", error)
          }
          
          reader.readAsDataURL(blob)
          break
        }
      }
    })
  }
}

Hooks.PostCard = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      // Check if click is on a link, button, or inside an action area
      const isInteractiveElement = e.target.closest('a, button')
      
      if (!isInteractiveElement) {
        const postUrl = this.el.dataset.postUrl
        if (postUrl) {
          this.pushEvent("navigate", {url: postUrl})
        }
      }
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Handle delete-post animation
window.addEventListener("phx:delete-post", (e) => {
  const postElement = document.getElementById(e.detail.id)
  if (postElement) {
    // Add fade-out classes
    postElement.classList.add('opacity-0', 'scale-95', 'transition-all', 'duration-300')
    // The actual removal happens via stream_delete after the animation
  }
})

// Stop propagation for nested links in post cards
document.addEventListener('click', (e) => {
  const target = e.target.closest('[data-post-link]')
  if (target) {
    e.stopPropagation()
  }
}, true)

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

