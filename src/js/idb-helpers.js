import Dexie from 'dexie';

const createTables = db => {
  return db.version(1).stores({
    user: 'userId, avatar, skinColour, name',
    stims: 'stimId, stimName, bodyPart, instructions, videoSrc, userId, shared',
    logs:
      '++id, stimId, timeTaken, preFace, postFace, preFeelings, postFeelings, dateTime'
  });
};

const createDB = () => {
  const db = new Dexie('stimmy_things');
  createTables(db);
  return db;
};

const createOrUpdateUser = (db, { userId, avatar, skinColour, name }) => {
  return db.user.put({ userId, avatar, skinColour, name });
};

const getUser = db => {
  return db.user.toArray().then(users => users[0]);
};

const addStim = (
  db,
  { stimId, stimName, bodyPart, instructions, videoSrc, userId, shared }
) => {
  return db.stims.put({
    stimId,
    stimName,
    bodyPart,
    instructions,
    videoSrc,
    userId,
    shared
  });
};

const addLog = (
  db,
  { stimId, timeTaken, preFace, postFace, preFeelings, postFeelings, dateTime }
) => {
  return db.logs.put({
    stimId,
    timeTaken,
    preFace,
    postFace,
    preFeelings,
    postFeelings,
    dateTime
  });
};

const getAllStims = db => {
  return db.stims.toArray();
};

const getAllLogs = db => {
  return db.logs.toArray();
};

const deleteStim = stimId => {
  return db.stims.delete(stimId);
};

const getAllTheData = db => {
  return db.transaction('r', [db.user, db.stims, db.logs], async () => {
    const user = await getUser(db);
    const stims = await getAllStims(db);
    const logs = await getAllLogs(db);

    return { user, stims, logs };
  });
};

const generateId = (prefix, length) => {
  const possibleChars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const idLengthArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  console.log('IDLENGTHARRAY', idLengthArray);
  const id = idLengthArray.reduce(acc => {
    console.log('HELLO?');
    console.log(
      'char: ',
      (acc += possibleChars.charAt(Math.floor(Math.random() * length)))
    );
    return (acc += possibleChars.charAt(Math.floor(Math.random() * length)));
  }, prefix);

  console.log('id: ', id);
  return id;
};

export default {
  createOrUpdateUser,
  getUser,
  generateId,
  createDB,
  getAllStims,
  addStim,
  addLog,
  getAllLogs,
  getAllTheData
};
