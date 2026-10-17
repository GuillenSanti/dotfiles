// Overlays for demo videos recorded with Playwright's `recordVideo`: a visible cursor, the current URL and a caption per step.
// Install it on the context before `newPage()`, then call `caption`, `moveAndClick`, `highlight` or `frame` at each step.
const OVERLAY = ({ captionLeft, captionWidth, urlCss }) => {
  const install = () => {
    if (document.getElementById('qa-cursor')) return
    const style = document.createElement('style')
    style.textContent = `
      #qa-cursor { position: fixed; z-index: 2147483647; width: 22px; height: 22px; margin: -11px 0 0 -11px;
        border-radius: 50%; background: rgba(229, 57, 53, .35); border: 2px solid #e53935; pointer-events: none;
        transition: transform .12s; left: -50px; top: -50px; }
      #qa-cursor.down { transform: scale(.6); background: rgba(229, 57, 53, .7); }
      #qa-url { position: fixed; z-index: 2147483646; ${urlCss} transform: translateX(-50%);
        background: #1f2937; color: #fff; font: 600 15px/1.2 -apple-system, sans-serif; padding: 7px 14px;
        border-radius: 8px; pointer-events: none; box-shadow: 0 2px 8px rgba(0,0,0,.25); white-space: nowrap; }
      #qa-caption { position: fixed; z-index: 2147483646; top: 50%; left: ${captionLeft}; transform: translate(-50%, -50%);
        width: ${captionWidth}; background: rgba(17, 24, 39, .92); color: #fff; font: 600 20px/1.35 -apple-system, sans-serif;
        padding: 12px 20px; border-radius: 10px; pointer-events: none; text-align: center; box-shadow: 0 4px 14px rgba(0,0,0,.3); }
      #qa-caption:empty { display: none; }
      .qa-highlight { outline: 4px solid #f59e0b !important; outline-offset: 3px; border-radius: 6px; }
    `
    document.head.appendChild(style)
    const cursor = document.createElement('div')
    cursor.id = 'qa-cursor'
    const url = document.createElement('div')
    url.id = 'qa-url'
    const caption = document.createElement('div')
    caption.id = 'qa-caption'
    try { caption.textContent = window.sessionStorage.getItem('qa-caption') || '' } catch (e) { caption.textContent = '' }
    document.body.append(cursor, url, caption)
    document.addEventListener('mousemove', (e) => {
      cursor.style.left = `${e.clientX}px`
      cursor.style.top = `${e.clientY}px`
    }, true)
    document.addEventListener('mousedown', () => cursor.classList.add('down'), true)
    document.addEventListener('mouseup', () => cursor.classList.remove('down'), true)
    setInterval(() => {
      url.textContent = `URL: ${location.pathname}`
    }, 200)
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', install)
  else install()
}

// Put the caption and the URL over an empty part of the page, e.g. `captionLeft: '25%'` when the left half is a PDF.
const installOverlay = (context, { captionLeft = '50%', captionWidth = '40%', urlCss = 'top: 8px; left: 50%;' } = {}) =>
  context.addInitScript(OVERLAY, { captionLeft, captionWidth, urlCss })

const caption = async (page, text, readMs = 2600) => {
  await page.evaluate((t) => {
    try { window.sessionStorage.setItem('qa-caption', t) } catch (e) {}
    const el = document.getElementById('qa-caption')
    if (el) el.textContent = t
  }, text)
  await page.waitForTimeout(readMs)
}

const moveTo = async (page, locator) => {
  const box = await locator.boundingBox()
  if (!box) return
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, { steps: 30 })
  await page.waitForTimeout(350)
}

const moveAndClick = async (page, locator) => {
  await locator.scrollIntoViewIfNeeded()
  await moveTo(page, locator)
  await locator.click()
}

const highlight = (page, locator, on) =>
  locator.evaluate((el, flag) => el.classList.toggle('qa-highlight', flag), on)

// Draws the highlight as a fixed box over the element, for elements whose container clips an outline.
const frame = async (page, locator, on) => {
  const locators = Array.isArray(locator) ? locator : [locator]
  const boxes = on ? await Promise.all(locators.map((l) => l.boundingBox())) : []
  // Several locators get one box around all of them.
  const box = boxes.length
    ? boxes.reduce((a, b) => {
        const x = Math.min(a.x, b.x)
        const y = Math.min(a.y, b.y)
        return { x, y, width: Math.max(a.x + a.width, b.x + b.width) - x, height: Math.max(a.y + a.height, b.y + b.height) - y }
      })
    : null
  await page.evaluate((b) => {
    document.getElementById('qa-frame')?.remove()
    if (!b) return
    const el = document.createElement('div')
    el.id = 'qa-frame'
    Object.assign(el.style, { position: 'fixed', zIndex: 2147483645, pointerEvents: 'none', border: '4px solid #f59e0b', borderRadius: '8px',
      left: `${b.x - 6}px`, top: `${b.y - 6}px`, width: `${b.width + 12}px`, height: `${b.height + 12}px`, boxSizing: 'border-box' })
    document.body.appendChild(el)
  }, box)
}

module.exports = { installOverlay, caption, moveTo, moveAndClick, highlight, frame }
