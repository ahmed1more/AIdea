/**
 * recompute_analytics.js
 *
 * Recomputes and corrects the Firestore `analytics` collection so each user's
 * derived stats match their actual `notes` data.
 *
 * Usage:
 *   node scripts/recompute_analytics.js            # Phase A — dry-run (read-only)
 *   node scripts/recompute_analytics.js --confirm   # Phase B — backup + write
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const fs = require('fs');
const path = require('path');

// ── Init Firebase Admin ─────────────────────────────────────────────────────
const serviceAccountPath = path.join(__dirname, '..', 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  console.error('serviceAccountKey.json not found at', serviceAccountPath);
  process.exit(1);
}
const serviceAccount = require(serviceAccountPath);
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const CONFIRM = process.argv.includes('--confirm');

// ── Helpers ─────────────────────────────────────────────────────────────────

/** Parse videoDuration from a note doc, with regex fallback on `notes` text. */
function getVideoDurationSeconds(data) {
  let dur = data.videoDuration ?? data.video_duration ?? 0;
  if (typeof dur === 'number' && dur > 0) return dur;

  // Fallback: parse "Duration: MM:SS" from the notes markdown
  const notesContent = data.notes ?? data.summary_content ?? '';
  const m = notesContent.match(/(?:المدة|Duration):\s*\**(\d+):(\d+)/);
  if (m) {
    const minutes = parseInt(m[1], 10) || 0;
    const seconds = parseInt(m[2], 10) || 0;
    dur = minutes * 60 + seconds;
  }
  return dur;
}

/** Resolve the category array from a note doc, matching Dart's fromFirestore. */
function getCategories(data) {
  let cats = [];
  if (data.category != null) {
    if (Array.isArray(data.category)) {
      cats = data.category.map(String);
    } else if (typeof data.category === 'string' && data.category.length > 0) {
      cats = [data.category];
    }
  } else if (Array.isArray(data.video_categories)) {
    cats = data.video_categories.map(String);
  } else if (Array.isArray(data.categories)) {
    cats = data.categories.map(String);
  }

  // Remove 'Uncategorized', ensure non-empty
  cats = cats.filter(c => c !== 'Uncategorized');
  if (cats.length === 0) cats = ['Technology & AI'];
  return cats;
}

/** Get createdAt as a JS Date from a note doc. */
function getCreatedAt(data) {
  const val = data.createdAt;
  if (val && typeof val.toDate === 'function') return val.toDate();
  if (val && typeof val === 'string') return new Date(val);
  return new Date();
}

/** Normalize a Date to midnight (date-only, local timezone). */
function toDateOnly(d) {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

/** Get the Monday of the ISO week containing `d`. */
function getISOWeekMonday(d) {
  const day = d.getDay() === 0 ? 7 : d.getDay(); // Mon=1 .. Sun=7
  const mon = new Date(d.getFullYear(), d.getMonth(), d.getDate() - (day - 1));
  return mon;
}

// ── Core Computation ────────────────────────────────────────────────────────

/**
 * Given an array of raw note doc data objects (all for one user),
 * compute the correct analytics.
 */
function computeAnalytics(userId, noteDocs) {
  const now = new Date();
  const todayDate = toDateOnly(now);
  const thisWeekMonday = getISOWeekMonday(todayDate);

  let notesCount = 0;
  let totalMinutes = 0;
  let favoriteNotesCount = 0;
  let totalKeyPoints = 0;
  let thisWeekVideos = 0;
  let thisMonthMinutes = 0;
  const categoryCount = {};

  // Collect dates (as date-only strings) for streak calculation
  const noteDates = new Set();

  for (const data of noteDocs) {
    notesCount++;

    // Duration
    const durSec = getVideoDurationSeconds(data);
    const durMin = Math.floor(durSec / 60);
    totalMinutes += durMin;

    // Favorites
    if (data.isFavorite === true) favoriteNotesCount++;

    // Key points
    const kp = data.keyPoints ?? [];
    if (Array.isArray(kp)) totalKeyPoints += kp.length;

    // Category — only first, matching Dart's incremental logic
    const cats = getCategories(data);
    const primaryCat = cats[0];
    categoryCount[primaryCat] = (categoryCount[primaryCat] || 0) + 1;

    // Created date
    const createdAt = getCreatedAt(data);
    const createdDate = toDateOnly(createdAt);

    // Streak dates
    const dateKey = createdDate.toISOString().slice(0, 10);
    noteDates.add(dateKey);

    // This week videos
    if (createdDate >= thisWeekMonday && createdDate <= todayDate) {
      thisWeekVideos++;
    }

    // This month minutes
    if (createdAt.getFullYear() === now.getFullYear() &&
        createdAt.getMonth() === now.getMonth()) {
      thisMonthMinutes += durMin;
    }
  }

  // Favorite category
  let favoriteCategory = 'None';
  let maxCatCount = 0;
  for (const [cat, count] of Object.entries(categoryCount)) {
    if (count > maxCatCount) {
      maxCatCount = count;
      favoriteCategory = cat;
    }
  }

  // Current streak — walk backward from today
  let currentStreak = 0;
  const cursor = new Date(todayDate);
  while (true) {
    const key = cursor.toISOString().slice(0, 10);
    if (noteDates.has(key)) {
      currentStreak++;
      cursor.setDate(cursor.getDate() - 1);
    } else {
      break;
    }
  }

  return {
    userId,
    notesCount,
    totalMinutes,
    totalSavedHours: Math.round((totalMinutes / 60) * 100) / 100,
    favoriteCategory,
    currentStreak,
    thisWeekVideos,
    thisMonthSavedHours: Math.round((thisMonthMinutes / 60) * 100) / 100,
    categoryCount,
    favoriteNotesCount,
    totalKeyPoints,
  };
}

// ── Diff Display ────────────────────────────────────────────────────────────

function printDiff(userId, oldData, newData) {
  const fields = [
    'notesCount', 'totalMinutes', 'totalSavedHours', 'favoriteCategory',
    'currentStreak', 'thisWeekVideos', 'thisMonthSavedHours',
    'favoriteNotesCount', 'totalKeyPoints',
  ];

  console.log(`\n${'='.repeat(70)}`);
  console.log(`  User: ${userId}`);
  console.log(`${'-'.repeat(70)}`);
  console.log(`  ${'Field'.padEnd(25)} ${'Old'.padEnd(20)} ${'New'.padEnd(20)} Change`);
  console.log(`  ${'-'.repeat(65)}`);

  let hasChanges = false;
  for (const f of fields) {
    const oldVal = oldData[f] ?? '(missing)';
    const newVal = newData[f] ?? '(missing)';
    const changed = JSON.stringify(oldVal) !== JSON.stringify(newVal);
    if (changed) hasChanges = true;
    const marker = changed ? ' <--' : '';
    console.log(`  ${f.padEnd(25)} ${String(oldVal).padEnd(20)} ${String(newVal).padEnd(20)}${marker}`);
  }

  // Category count diff
  const oldCats = oldData.categoryCount || {};
  const newCats = newData.categoryCount || {};
  const allCats = new Set([...Object.keys(oldCats), ...Object.keys(newCats)]);
  if (allCats.size > 0) {
    console.log(`  ${'-'.repeat(65)}`);
    console.log(`  categoryCount:`);
    for (const cat of allCats) {
      const ov = oldCats[cat] ?? 0;
      const nv = newCats[cat] ?? 0;
      const changed = ov !== nv;
      if (changed) hasChanges = true;
      const marker = changed ? ' <--' : '';
      console.log(`    ${cat.padEnd(23)} ${String(ov).padEnd(20)} ${String(nv).padEnd(20)}${marker}`);
    }
  }

  if (!hasChanges) {
    console.log(`  No changes needed`);
  }

  return hasChanges;
}

// ── Main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`\nAnalytics Recomputation Script`);
  console.log(`   Mode: ${CONFIRM ? 'WRITE (--confirm)' : 'DRY-RUN (read-only)'}`);
  console.log(`   Time: ${new Date().toISOString()}\n`);

  // ── Step 2: Schema confirmation — sample 5 notes ──────────────────────
  console.log('Step 2 -- Sampling 5 notes to verify schema...\n');
  const sampleSnap = await db.collection('notes').limit(5).get();
  if (sampleSnap.empty) {
    console.log('WARNING: No notes found in collection. Nothing to recompute.');
    process.exit(0);
  }

  for (const doc of sampleSnap.docs) {
    const data = doc.data();
    console.log(`  Note ${doc.id}:`);
    console.log(`    Fields: ${Object.keys(data).join(', ')}`);
    const dur = data.videoDuration ?? data.video_duration ?? '(absent)';
    const kp = Array.isArray(data.keyPoints) ? data.keyPoints.length : '(absent)';
    console.log(`    videoDuration=${dur}  keyPoints.length=${kp}  isFavorite=${data.isFavorite ?? '(absent)'}`);
    console.log();
  }

  // ── Read all notes, group by userId ───────────────────────────────────
  console.log('Reading all notes...');
  const allNotesSnap = await db.collection('notes').get();
  console.log(`   Found ${allNotesSnap.size} notes total.\n`);

  const notesByUser = {};
  for (const doc of allNotesSnap.docs) {
    const data = doc.data();
    const uid = data.userId ?? data.user_id;
    if (!uid) continue;
    if (!notesByUser[uid]) notesByUser[uid] = [];
    notesByUser[uid].push(data);
  }

  const userIds = Object.keys(notesByUser);
  console.log(`   ${userIds.length} unique users with notes.\n`);

  // ── Read existing analytics ───────────────────────────────────────────
  console.log('Reading existing analytics...');
  const allAnalyticsSnap = await db.collection('analytics').get();
  const existingAnalytics = {};
  for (const doc of allAnalyticsSnap.docs) {
    existingAnalytics[doc.id] = doc.data();
  }
  console.log(`   Found ${allAnalyticsSnap.size} analytics docs.\n`);

  // ── Compute correct analytics per user ────────────────────────────────
  console.log('Computing correct analytics...\n');
  const computed = {};
  for (const uid of userIds) {
    computed[uid] = computeAnalytics(uid, notesByUser[uid]);
  }

  // ── Print diff table ──────────────────────────────────────────────────
  console.log('DIFF TABLE -- Old vs. Correct values (<-- marks differences)\n');
  let usersWithChanges = 0;
  let usersNoChanges = 0;

  for (const uid of userIds) {
    const old = existingAnalytics[uid] || {};
    const hasChanges = printDiff(uid, old, computed[uid]);
    if (hasChanges) usersWithChanges++;
    else usersNoChanges++;
  }

  // Also check for analytics docs with no notes (orphans)
  const orphanIds = Object.keys(existingAnalytics).filter(id => !notesByUser[id]);
  if (orphanIds.length > 0) {
    console.log(`\nWARNING: ${orphanIds.length} analytics doc(s) have NO matching notes:`);
    for (const id of orphanIds) {
      console.log(`    - ${id} (notesCount=${existingAnalytics[id].notesCount ?? '?'})`);
    }
  }

  console.log(`\n${'='.repeat(70)}`);
  console.log(`  Summary: ${usersWithChanges} users need updates, ${usersNoChanges} already correct.`);
  if (orphanIds.length > 0) console.log(`           ${orphanIds.length} orphan analytics docs (no notes).`);
  console.log(`${'='.repeat(70)}\n`);

  // ── Phase B: Write (if --confirm) ─────────────────────────────────────
  if (!CONFIRM) {
    console.log('Dry-run complete. No writes performed.');
    console.log('   Re-run with --confirm to backup and write.\n');
    process.exit(0);
  }

  // Backup current analytics
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupPath = path.join(__dirname, `analytics_backup_${timestamp}.json`);
  const backupData = {};
  for (const [id, data] of Object.entries(existingAnalytics)) {
    backupData[id] = data;
  }
  fs.writeFileSync(backupPath, JSON.stringify(backupData, null, 2), 'utf8');
  console.log(`Backup saved to: ${backupPath}\n`);

  // Batched writes (max 500 per batch)
  const BATCH_SIZE = 500;
  const allUserIds = userIds;
  let totalWritten = 0;

  for (let i = 0; i < allUserIds.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = allUserIds.slice(i, i + BATCH_SIZE);

    for (const uid of chunk) {
      const ref = db.collection('analytics').doc(uid);
      batch.set(ref, {
        ...computed[uid],
        lastUpdated: FieldValue.serverTimestamp(),
      }, { merge: false }); // full overwrite to clear stale fields
    }

    await batch.commit();
    totalWritten += chunk.length;
    console.log(`   Batch ${Math.floor(i / BATCH_SIZE) + 1}: wrote ${chunk.length} docs (${totalWritten}/${allUserIds.length} total)`);
  }

  console.log(`\nDone! Updated ${totalWritten} analytics documents.\n`);

  // ── Step 6: Spot check — re-read 3 users ──────────────────────────────
  console.log('Spot check -- re-reading 3 users...\n');
  const spotCheckIds = allUserIds.slice(0, Math.min(3, allUserIds.length));

  for (const uid of spotCheckIds) {
    const doc = await db.collection('analytics').doc(uid).get();
    const stored = doc.data();
    const expected = computed[uid];

    console.log(`  User: ${uid}`);
    console.log(`    notesCount:        stored=${stored.notesCount}  expected=${expected.notesCount}  ${stored.notesCount === expected.notesCount ? 'OK' : 'MISMATCH'}`);
    console.log(`    totalMinutes:      stored=${stored.totalMinutes}  expected=${expected.totalMinutes}  ${stored.totalMinutes === expected.totalMinutes ? 'OK' : 'MISMATCH'}`);
    console.log(`    favoriteCategory:  stored=${stored.favoriteCategory}  expected=${expected.favoriteCategory}  ${stored.favoriteCategory === expected.favoriteCategory ? 'OK' : 'MISMATCH'}`);
    console.log(`    favoriteNotesCount: stored=${stored.favoriteNotesCount}  expected=${expected.favoriteNotesCount}  ${stored.favoriteNotesCount === expected.favoriteNotesCount ? 'OK' : 'MISMATCH'}`);
    console.log(`    totalKeyPoints:    stored=${stored.totalKeyPoints}  expected=${expected.totalKeyPoints}  ${stored.totalKeyPoints === expected.totalKeyPoints ? 'OK' : 'MISMATCH'}`);
    console.log(`    currentStreak:     stored=${stored.currentStreak}  expected=${expected.currentStreak}  ${stored.currentStreak === expected.currentStreak ? 'OK' : 'MISMATCH'}`);
    console.log(`    thisWeekVideos:    stored=${stored.thisWeekVideos}  expected=${expected.thisWeekVideos}  ${stored.thisWeekVideos === expected.thisWeekVideos ? 'OK' : 'MISMATCH'}`);
    console.log();
  }
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
