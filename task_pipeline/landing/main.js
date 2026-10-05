// Task Pipeline landing page: the deal, the project row, the task list and
// the random draw. Everything here is a demo; nothing is saved.

(function () {
  'use strict';

  const PROJECTS = [
    { id: 'kitchen', name: 'Kitchen renovation', summary: 'Pick the tiles, book the plumber and keep the budget in one place.', tasks: [
      { id: 'k1', name: 'Measure the back wall', done: true },
      { id: 'k2', name: 'Choose three tile samples', done: false },
      { id: 'k3', name: 'Get two plumber quotes', done: false },
      { id: 'k4', name: 'Order the extractor hood', done: false } ] },
    { id: 'thesis', name: 'Thesis — chapter 3', summary: 'Methods chapter. Finish the data section before the tutor meeting.', tasks: [
      { id: 't1', name: 'Clean the survey dataset', done: true },
      { id: 't2', name: 'Draft section 3.2', done: false },
      { id: 't3', name: 'Redo figure 4 in colour', done: false },
      { id: 't4', name: 'Send the draft to my tutor', done: false } ] },
    { id: 'lisbon', name: 'Trip to Lisbon', summary: 'Four days in October. Flights booked, everything else still open.', tasks: [
      { id: 'l1', name: 'Book a flat near Alfama', done: false },
      { id: 'l2', name: 'Reserve Belém Tower tickets', done: false },
      { id: 'l3', name: 'Download offline maps', done: true } ] },
    { id: 'flutter', name: 'Learn Flutter', summary: 'One module a week, building a real app along the way.', tasks: [
      { id: 'f1', name: 'Finish the BLoC module', done: true },
      { id: 'f2', name: 'Add Firebase sign-in', done: true },
      { id: 'f3', name: 'Build the horizontal scroll', done: false },
      { id: 'f4', name: 'Write the README', done: false } ] },
    { id: 'garden', name: 'Balcony garden', summary: 'Herbs and tomatoes, planted before the first frost.', tasks: [
      { id: 'g1', name: 'Buy two planters', done: false },
      { id: 'g2', name: 'Repot the basil', done: false },
      { id: 'g3', name: 'Set a watering reminder', done: false } ] },
    { id: 'portfolio', name: 'Portfolio site', summary: 'Three case studies and a contact page.', tasks: [
      { id: 'p1', name: 'Pick the three projects', done: true },
      { id: 'p2', name: 'Write the About section', done: false },
      { id: 'p3', name: 'Take new screenshots', done: false } ] }
  ];

  const FLIP_MS = 520; // a little under the 560ms flip, so the redraw overlaps its end

  const state = {
    selected: PROJECTS[0],
    flipped: false,
    lastDrawn: null
  };

  const $ = (id) => document.getElementById(id);

  function doneCount(project) {
    return project.tasks.filter((t) => t.done).length;
  }

  // ---- Fixed-size scenes scaled to fit ------------------------------------
  // The table (660 × 820) and the flip card (460 × 620) are positioned in
  // pixels, like the design. On a narrow screen the whole scene shrinks:
  // a 330px-wide frame gives scale 0.5, so the frame becomes 410px tall.

  function fitScenes() {
    const frames = document.querySelectorAll('.fit-frame');
    const fit = (frame) => {
      const w = Number(frame.dataset.fitWidth);
      const h = Number(frame.dataset.fitHeight);
      const scale = Math.min(1, frame.clientWidth / w);
      frame.firstElementChild.style.transform = 'scale(' + scale + ')';
      frame.style.height = h * scale + 'px';
    };
    frames.forEach(fit);
    if ('ResizeObserver' in window) {
      const observer = new ResizeObserver((entries) => entries.forEach((e) => fit(e.target)));
      frames.forEach((f) => observer.observe(f));
    } else {
      window.addEventListener('resize', () => frames.forEach(fit));
    }
  }

  // ---- Sheet 01: the deal --------------------------------------------------

  let dealTimer;

  function setUpDeal() {
    const table = $('table');
    dealTimer = setTimeout(() => table.classList.add('is-dealt'), 650);
    $('redeal').addEventListener('click', () => {
      clearTimeout(dealTimer);
      table.classList.remove('is-dealt');
      dealTimer = setTimeout(() => table.classList.add('is-dealt'), 1000);
    });
  }

  // ---- Sheet 02: the project row and its tasks -----------------------------

  function renderRow() {
    const row = $('card-row');
    PROJECTS.forEach((p) => {
      const card = document.createElement('button');
      card.type = 'button';
      card.className = 'project-card';
      card.dataset.id = p.id;

      const name = document.createElement('h3');
      name.className = 'pc-name';
      name.textContent = p.name;

      const summary = document.createElement('p');
      summary.className = 'pc-summary';
      summary.textContent = p.summary;

      const foot = document.createElement('p');
      foot.className = 'pc-foot';
      const count = document.createElement('span');
      count.dataset.countFor = p.id;
      const dot = document.createElement('span');
      dot.className = 'dot';
      dot.setAttribute('aria-hidden', 'true');
      foot.append(count, dot);

      card.append(name, summary, foot);
      card.addEventListener('click', () => select(p));
      row.appendChild(card);
    });
  }

  function select(project) {
    state.selected = project;
    unflip();
    renderSelection();
  }

  function renderSelection() {
    const sel = state.selected;
    document.querySelectorAll('.project-card').forEach((card) => {
      card.setAttribute('aria-pressed', String(card.dataset.id === sel.id));
    });
    $('tasks-title').textContent = sel.name;
    $('drawing-from').textContent = sel.name;
    renderTasks();
  }

  function renderTasks() {
    const list = $('task-list');
    list.replaceChildren();
    state.selected.tasks.forEach((task) => {
      const item = document.createElement('li');
      const label = document.createElement('label');
      const box = document.createElement('input');
      box.type = 'checkbox';
      box.checked = task.done;
      box.addEventListener('change', () => {
        task.done = box.checked;
        renderProgress();
      });
      const text = document.createElement('span');
      text.textContent = task.name;
      label.append(box, text);
      item.appendChild(label);
      list.appendChild(item);
    });
    renderProgress();
  }

  // Counts appear on the hero cards, the row cards and the task panel.
  function renderProgress() {
    PROJECTS.forEach((p) => {
      const text = doneCount(p) + '/' + p.tasks.length + ' tasks done';
      document.querySelectorAll('[data-count-for="' + p.id + '"]').forEach((el) => {
        el.textContent = text;
      });
    });
    const sel = state.selected;
    const n = doneCount(sel);
    $('tasks-progress').textContent = n + ' of ' + sel.tasks.length + ' done';
    $('progress-fill').style.width = Math.round((n / sel.tasks.length) * 100) + '%';
  }

  // ---- Sheet 03: the random draw -----------------------------------------

  let flipTimer;

  function draw() {
    const sel = state.selected;
    const open = sel.tasks.filter((t) => !t.done);
    let name;
    if (!open.length) {
      name = 'Nothing left — every task is done.';
    } else {
      // Avoid drawing the same task twice in a row when there's a choice.
      const pool = open.length > 1 ? open.filter((t) => t.name !== state.lastDrawn) : open;
      name = pool[Math.floor(Math.random() * pool.length)].name;
    }
    state.lastDrawn = name;
    $('drawn-project').textContent = sel.name;
    $('drawn-name').textContent = name;
    setFlipped(true);
  }

  function setFlipped(flipped) {
    state.flipped = flipped;
    $('flip').classList.toggle('is-flipped', flipped);
    $('pick-label').textContent = flipped ? 'Draw again' : 'Pick a random task';
  }

  function unflip() {
    clearTimeout(flipTimer);
    setFlipped(false);
  }

  function setUpPick() {
    $('pick-btn').addEventListener('click', () => {
      clearTimeout(flipTimer);
      if (state.flipped) {
        // Turn the card face down first, then draw once it's hidden.
        setFlipped(false);
        flipTimer = setTimeout(draw, FLIP_MS);
      } else {
        draw();
      }
    });
  }

  // ---- Start ----------------------------------------------------------------

  fitScenes();
  setUpDeal();
  renderRow();
  renderSelection();
  setUpPick();
})();
