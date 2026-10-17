(() => {
  'use strict';
  const $ = (id) => document.getElementById(id);
  const hud = $('hud');
  const toast = $('announcement');
  const fill = $('progress');
  const clock = $('clock');
  const title = $('heading');
  const caption = $('caption');
  const status = $('status-tag');
  let settings = { enabled: true, showWhenPaused: true, showAnnouncements: true, announcementMs: 4200 };
  let state = null;
  let receivedAt = performance.now();
  let toastExpires = 0;

  const clamp = (n, min, max) => Math.max(min, Math.min(max, n));
  const remaining = (ms, advancing) => Math.max(0, (Number(ms) || 0) - (advancing ? performance.now() - receivedAt : 0));
  const format = (ms) => {
    const seconds = Math.max(0, Math.ceil(ms / 1000));
    return `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`;
  };
  const update = () => {
    if (!settings.enabled || !state || (!settings.showWhenPaused && (!state.enabled || state.paused))) {
      hud.classList.add('hidden');
      toast.classList.add('hidden');
      return;
    }
    hud.classList.remove('hidden');
    const activeRemaining = state.active && remaining(state.active.remainingMs, true);
    const isActive = !!state.active && activeRemaining > 0;
    const suspended = !state.enabled || state.paused;
    hud.classList.toggle('is-active', isActive);
    hud.classList.toggle('is-paused', suspended && !isActive);
    let percent;
    if (isActive) {
      status.textContent = 'EFFECT ACTIVE';
      title.textContent = state.active.name || state.active.id || 'Chaos effect';
      caption.textContent = state.active.description || 'Active for everyone';
      clock.textContent = format(activeRemaining);
      percent = activeRemaining / Math.max(1, Number(state.active.durationMs) || 1);
    } else if (!state.enabled) {
      status.textContent = 'DISABLED';
      title.textContent = 'Chaos is off';
      caption.textContent = 'Waiting for an administrator';
      clock.textContent = '--:--';
      percent = 0;
    } else if (state.paused) {
      status.textContent = 'PAUSED';
      title.textContent = 'Chaos on hold';
      caption.textContent = 'Countdown frozen by an administrator';
      clock.textContent = format(remaining(state.untilNextMs, false));
      percent = remaining(state.untilNextMs, false) / Math.max(1, Number(state.intervalMs) || 1);
    } else {
      status.textContent = state.queued ? 'UP NEXT: QUEUED' : 'NEXT EFFECT';
      title.textContent = 'Chaos incoming';
      caption.textContent = state.queued ? 'A surprise has been selected' : 'All players • server-wide';
      const nextRemaining = remaining(state.untilNextMs, true);
      clock.textContent = format(nextRemaining);
      percent = nextRemaining / Math.max(1, Number(state.intervalMs) || 1);
    }
    fill.style.transform = `scaleX(${clamp(percent, 0, 1)})`;
    if (performance.now() >= toastExpires) toast.classList.add('hidden');
  };

  window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || typeof data !== 'object') return;
    if (data.type === 'setup') {
      const ui = data.ui || {};
      settings.enabled = ui.enabled !== false;
      settings.showWhenPaused = ui.showWhenPaused !== false;
      settings.showAnnouncements = ui.showAnnouncements !== false;
      settings.announcementMs = clamp(Number(ui.announcementMs) || 4200, 500, 15000);
      $('brand').textContent = String(ui.title || 'CHAOS MODE').slice(0, 32);
      const accent = String(ui.accent || '#ef4444');
      if (/^#[0-9a-fA-F]{6}$/.test(accent)) document.documentElement.style.setProperty('--accent', accent);
      document.documentElement.style.setProperty('--card-width', `${clamp(Number(ui.widthPx) || 420, 280, 760)}px`);
      document.documentElement.style.setProperty('--top-offset', `${clamp(Number(ui.topPx) || 24, 0, 300)}px`);
    } else if (data.type === 'state' && data.state && typeof data.state === 'object') {
      state = data.state;
      receivedAt = performance.now();
    } else if (data.type === 'announce' && settings.showAnnouncements) {
      $('announcement-name').textContent = String(data.name || 'Chaos effect').slice(0, 90);
      $('announcement-description').textContent = String(data.description || '').slice(0, 180);
      toastExpires = performance.now() + settings.announcementMs;
      toast.classList.remove('hidden');
    } else if (data.type === 'stop') {
      if (state) state.active = null;
      toastExpires = 0;
      toast.classList.add('hidden');
    } else if (data.type === 'hide') {
      settings.enabled = false;
    }
    update();
  });
  setInterval(update, 100);
})();
