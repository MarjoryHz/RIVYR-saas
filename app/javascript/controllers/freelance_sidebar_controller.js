import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static classes = [ "collapsed" ]

  connect() {
    this.collapsedClass = this.hasCollapsedClass ? this.collapsedClass : "is-collapsed"
  }

  toggle() {
    this.element.classList.toggle(this.collapsedClass)
    document.body.classList.toggle("freelance-sidebar-collapsed", this.element.classList.contains(this.collapsedClass))
  }
}
