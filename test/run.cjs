/* Host-side tests of the actual pure .ets modules. Not a HarmonyOS runtime test. */
const fs = require('node:fs');
const path = require('node:path');
const Module = require('node:module');
const assert = require('node:assert/strict');
const ide = process.env.DEVECO_ROOT || 'F:/Apps/DevEco Studio';
const ts = require(path.join(ide, 'tools/hvigor/hvigor/node_modules/typescript'));
Module._extensions['.ets'] = (module, filename) => {
  const output = ts.transpileModule(fs.readFileSync(filename, 'utf8'), {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 }
  });
  module._compile(output.outputText, filename);
};
const source = '../entry/src/main/ets/';
const { SCENES, sceneById } = require(source + 'config/Scenes.ets');
const { LocalDialogueService, evaluate, MAX_USER_TURNS } = require(source + 'service/dialogue/DialogueService.ets');
const engine = new LocalDialogueService();
const results = [];
async function check(name, action) {
  try { await action(); results.push({ name, status: 'pass' }); console.log('PASS ' + name); }
  catch (error) { results.push({ name, status: 'fail', error: error.message }); console.error('FAIL ' + name + ': ' + error.message); }
}
function exercise(sceneId, lines) {
  const scene = sceneById(sceneId);
  let session = engine.start(scene);
  for (const line of lines) session = engine.send(scene, session, line);
  return { session, report: engine.finish(scene, session) };
}
(async () => {
  await check('stable unique scene/task identifiers', () => {
    assert.equal(new Set(SCENES.map(s => s.id)).size, 3);
    const ids = SCENES.flatMap(s => s.tasks.map(t => t.id));
    assert.equal(new Set(ids).size, ids.length);
    assert.throws(() => sceneById('unknown'));
  });
  await check('restaurant complete dialogue and exact user evidence', () => {
    const { session, report } = exercise('restaurant-v1', ["I'd like two sandwiches, please.", 'To go, please.', "That's correct. How much is it?"]);
    assert.equal(report.completed, true);
    for (const r of report.results) {
      const turn = session.turns.find(t => t.id === r.evidenceTurnId);
      assert.equal(turn.role, 'user'); assert.equal(turn.text, r.evidence);
    }
    assert.equal(new Set(session.turns.map(t => t.id)).size, session.turns.length);
  });
  await check('airport complete dialogue', () => {
    assert.equal(exercise('airport-v1', ["I'm flying to London.", 'Here is my passport.', 'I have one bag to check in.', 'What time does boarding start?']).report.completed, true);
  });
  await check('campus complete dialogue', () => {
    assert.equal(exercise('campus-v1', ['My name is Lin.', 'I study computer science.', 'Would you like to join the English club?', "Let's meet at three tomorrow."]).report.completed, true);
  });
  await check('each missing restaurant goal remains missing', () => {
    const lines = ['I would like pizza.', 'Two cups, please.', 'To go, please.', "That's correct."];
    for (let i = 0; i < lines.length; i++) {
      const result = exercise('restaurant-v1', lines.filter((_, j) => j !== i)).report;
      assert.equal(result.results[i].completed, false);
      assert.equal(result.completed, false);
    }
  });
  await check('partner words do not count as learner task completion', () => {
    const scene = SCENES[0]; const session = engine.start(scene);
    session.turns[0].text = "I'd like two sandwiches to go. That's correct.";
    assert.ok(evaluate(scene, session).every(r => !r.completed));
  });
  await check('negation does not satisfy order', () => {
    const { report } = exercise('restaurant-v1', ["I don't want two sandwiches.", 'Not to go.', 'The order is not correct.']);
    assert.ok(report.results.every(r => !r.completed));
  });
  await check('zero baggage is a valid baggage statement', () => {
    assert.equal(exercise('airport-v1', ['No bags.']).report.results.find(r => r.taskId === 'airport-baggage').completed, true);
  });
  await check('unrelated English and Chinese do not satisfy restaurant tasks', () => {
    for (const line of ['The weather is nice.', '我想去图书馆']) {
      assert.ok(exercise('restaurant-v1', [line]).report.results.every(r => !r.completed));
    }
  });
  await check('empty and oversized inputs rejected without mutating session', () => {
    const session = engine.start(SCENES[0]);
    assert.throws(() => engine.send(SCENES[0], session, '  '));
    assert.throws(() => engine.send(SCENES[0], session, 'a'.repeat(501)));
    assert.equal(session.turns.length, 1);
  });
  await check('finished/cancelled sessions cannot accept input or reports', () => {
    for (const status of ['finished', 'cancelled']) {
      const session = engine.start(SCENES[0]); session.status = status;
      assert.throws(() => engine.send(SCENES[0], session, 'Hello'));
      assert.throws(() => engine.finish(SCENES[0], session));
    }
  });
  await check('scene mismatch rejected', () => {
    assert.throws(() => engine.send(SCENES[1], engine.start(SCENES[0]), 'Hello'));
  });
  await check('turn cap enforced and report still available', () => {
    let session = engine.start(SCENES[0]);
    for (let i = 0; i < MAX_USER_TURNS; i++) session = engine.send(SCENES[0], session, 'Hello');
    assert.throws(() => engine.send(SCENES[0], session, 'Hello'));
    assert.equal(engine.finish(SCENES[0], session).sessionId, session.id);
  });
  await check('reports have one to three actionable suggestions and no pronunciation score', () => {
    for (const scene of SCENES) {
      const report = engine.finish(scene, engine.start(scene));
      assert.ok(report.suggestions.length >= 1 && report.suggestions.length <= 3);
      assert.equal(report.source, 'offline-rules-v1');
      assert.equal('pronunciationScore' in report, false);
    }
  });
  // Mock only the platform boundary; this does not test real Preferences or power-loss behavior.
  const disk = new Map();
  let memory = new Map(disk);
  let failFlush = false;
  const store = {
    async get(key, fallback) { return memory.has(key) ? memory.get(key) : fallback; },
    async put(key, value) { memory.set(key, value); },
    async flush() {
      if (failFlush) { failFlush = false; throw new Error('injected flush failure'); }
      disk.clear(); for (const [k, v] of memory) disk.set(k, v);
    }
  };
  const load = Module._load;
  Module._load = function (request, parent, isMain) {
    if (request === '@kit.ArkData') return { preferences: { getPreferences: async () => store } };
    return load.call(this, request, parent, isMain);
  };
  const { PracticeRepository } = require(source + 'repository/PracticeRepository.ets');
  Module._load = load;
  let repository = new PracticeRepository();
  await repository.open({});
  const practice = exercise('restaurant-v1', ["I'd like two sandwiches.", 'To go.', "That's correct."]);
  practice.session.status = 'finished';
  const record = { id: practice.session.id, sceneId: practice.session.sceneId, session: practice.session, report: practice.report };
  await check('repository save is idempotent for a session', async () => {
    await repository.save(record); await repository.save(record);
    assert.equal((await repository.list()).length, 1);
  });
  await check('repository rejects mismatched report/session IDs', async () => {
    await assert.rejects(repository.save({ ...record, id: 'wrong' }));
    assert.equal((await repository.list()).length, 1);
  });
  await check('repository reload from mock disk and delete', async () => {
    memory = new Map(disk); repository = new PracticeRepository(); await repository.open({});
    assert.equal((await repository.list())[0].id, record.id);
    await repository.remove(record.id);
    memory = new Map(disk); assert.equal((await repository.list()).length, 0);
  });
  await check('flush failure is reported and previous in-memory value restored', async () => {
    failFlush = true; await assert.rejects(repository.save(record));
    assert.equal((await repository.list()).length, 0);
    await repository.save(record); assert.equal((await repository.list()).length, 1);
  });
  await check('malformed data is rejected without silent overwrite', async () => {
    const previous = memory.get('history-v1');
    for (const bad of ['not json', '{}', '[null]', JSON.stringify([{ ...record, session: { ...record.session, turns: [null] } }])]) {
      memory.set('history-v1', bad);
      await assert.rejects(repository.list()); assert.equal(memory.get('history-v1'), bad);
    }
    memory.set('history-v1', previous);
  });
  await check('settings survive mock reload and history clearing does not delete settings', async () => {
    await repository.saveSettings({ id: 'settings-v1', showHints: false, mode: 'offline' });
    await repository.clearHistory(); memory = new Map(disk);
    assert.equal((await repository.settings()).showHints, false);
    assert.equal((await repository.list()).length, 0);
  });
  const out = path.join(__dirname, 'results.json');
  fs.writeFileSync(out, JSON.stringify({ at: new Date().toISOString(), environment: 'Node host, actual .ets transpiled by installed TypeScript; no device runtime', results }, null, 2));
  console.log(`${results.filter(r => r.status === 'pass').length}/${results.length} passed`);
  if (results.some(r => r.status === 'fail')) process.exitCode = 1;
})().catch(error => { console.error(error); process.exitCode = 1; });
