import { ApplicationController } from './application_controller'

export class CseCalendarController extends ApplicationController {
  static targets = ['calendar', 'datesList', 'hiddenInputs', 'monthLabel']
  static values = { dates: Array, currentMonth: String }

  declare calendarTarget: HTMLElement
  declare datesListTarget: HTMLElement
  declare hiddenInputsTarget: HTMLElement
  declare monthLabelTarget: HTMLElement
  declare datesValue: string[]
  declare currentMonthValue: string

  private currentDate!: Date

  connect() {
    this.currentDate = new Date()
    this.currentDate.setDate(1)
    if (this.currentMonthValue) {
      this.currentDate = new Date(this.currentMonthValue + '-01')
    }
    this.render()
  }

  previousMonth() {
    this.currentDate.setMonth(this.currentDate.getMonth() - 1)
    this.render()
  }

  nextMonth() {
    this.currentDate.setMonth(this.currentDate.getMonth() + 1)
    this.render()
  }

  toggleDate(event: Event) {
    const button = event.currentTarget as HTMLButtonElement
    const dateStr = button.dataset.date
    if (!dateStr) return

    const index = this.datesValue.indexOf(dateStr)
    if (index >= 0) {
      this.datesValue = this.datesValue.filter((d) => d !== dateStr)
    } else {
      this.datesValue = [...this.datesValue, dateStr].sort()
    }
    this.render()
  }

  removeDate(event: Event) {
    const button = event.currentTarget as HTMLButtonElement
    const dateStr = button.dataset.date
    if (!dateStr) return

    this.datesValue = this.datesValue.filter((d) => d !== dateStr)
    this.render()
  }

  private render() {
    this.renderCalendar()
    this.renderDatesList()
    this.renderHiddenInputs()
  }

  private renderCalendar() {
    const year = this.currentDate.getFullYear()
    const month = this.currentDate.getMonth()

    const monthNames = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ]
    this.monthLabelTarget.textContent = `${monthNames[month]} ${year}`

    const firstDay = new Date(year, month, 1)
    const lastDay = new Date(year, month + 1, 0)

    // Monday=0 adjustment (JS getDay: 0=Sun)
    let startDay = firstDay.getDay() - 1
    if (startDay < 0) startDay = 6

    const today = new Date()
    today.setHours(0, 0, 0, 0)

    let html = '<table class="cse-calendar-grid"><thead><tr>'
    const dayHeaders = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di']
    dayHeaders.forEach((d) => {
      html += `<th>${d}</th>`
    })
    html += '</tr></thead><tbody><tr>'

    // Empty cells before first day
    for (let i = 0; i < startDay; i++) {
      html += '<td></td>'
    }

    for (let day = 1; day <= lastDay.getDate(); day++) {
      const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
      const isSelected = this.datesValue.includes(dateStr)
      const cellDate = new Date(year, month, day)
      const isPast = cellDate < today

      const classes = ['cse-calendar-day']
      if (isSelected) classes.push('cse-calendar-day--selected')
      if (isPast) classes.push('cse-calendar-day--past')

      html += `<td><button type="button" class="${classes.join(' ')}" data-date="${dateStr}" data-action="cse-calendar#toggleDate"${isPast ? ' disabled' : ''}>${day}</button></td>`

      if ((startDay + day) % 7 === 0) {
        html += '</tr><tr>'
      }
    }

    html += '</tr></tbody></table>'
    this.calendarTarget.innerHTML = html
  }

  private renderDatesList() {
    if (this.datesValue.length === 0) {
      this.datesListTarget.innerHTML =
        '<p class="fr-text-mention--grey fr-text--sm">Aucune date de CSE définie</p>'
      return
    }

    const formatter = new Intl.DateTimeFormat('fr-FR', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })

    let html = ''
    this.datesValue.forEach((dateStr) => {
      const date = new Date(dateStr + 'T00:00:00')
      const deadline = new Date(date)
      deadline.setDate(deadline.getDate() - 14)

      const deadlineFormatter = new Intl.DateTimeFormat('fr-FR', {
        day: 'numeric',
        month: 'long',
        year: 'numeric'
      })

      const formattedDate = formatter.format(date)
      const capitalizedDate = formattedDate.charAt(0).toUpperCase() + formattedDate.slice(1)

      html += `<li class="cse-date-item">
        <div class="flex justify-between align-center">
          <div>
            <p class="fr-mb-0 fr-text--bold">${capitalizedDate}</p>
            <p class="fr-mb-0 fr-text--sm fr-text-mention--grey">Date limite de dépôt : ${deadlineFormatter.format(deadline)}</p>
          </div>
          <button type="button" class="fr-btn fr-btn--tertiary fr-btn--sm fr-icon-delete-line" data-date="${dateStr}" data-action="cse-calendar#removeDate" title="Supprimer cette date"></button>
        </div>
      </li>`
    })

    this.datesListTarget.innerHTML = `<ul class="cse-dates-list">${html}</ul>`
  }

  private renderHiddenInputs() {
    let html = ''
    this.datesValue.forEach((dateStr) => {
      html += `<input type="hidden" name="cse_dates[]" value="${dateStr}">`
    })
    this.hiddenInputsTarget.innerHTML = html
  }
}
