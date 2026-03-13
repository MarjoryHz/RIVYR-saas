// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const syncFreelanceSidebarState = (sidebar) => {
  if (!sidebar) return

  const collapsed = sidebar.classList.contains("is-collapsed")
  document.body.classList.toggle("freelance-sidebar-collapsed", collapsed)

  const toggle = sidebar.querySelector("[data-freelance-sidebar-toggle]")
  if (toggle) {
    toggle.setAttribute("aria-expanded", (!collapsed).toString())
  }
}

document.addEventListener("click", (event) => {
  const toggle = event.target.closest("[data-freelance-sidebar-toggle]")
  if (!toggle) return

  const sidebar = toggle.closest("[data-freelance-sidebar]")
  if (!sidebar) return

  sidebar.classList.toggle("is-collapsed")
  syncFreelanceSidebarState(sidebar)
})

document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-freelance-sidebar]").forEach(syncFreelanceSidebarState)
})
