import app from './elm-init';

import idb from './port-handlers/idb-handlers';
import flickity from './port-handlers/flickity-handlers';
import hotspots from './port-handlers/hotspots-handlers';
import firebase from './port-handlers/firebase-handlers';

import defaultStims from '../json/defaultStims.json';

app.ports.initCarousel.subscribe(flickity.initCarousel);
app.ports.videoCarousel.subscribe(flickity.videoCarousel);
app.ports.retrieveChosenAvatar.subscribe(flickity.retrieveChosenAvatar);

app.ports.initHotspots.subscribe(hotspots.initHotspots);
app.ports.initDB.subscribe(() => idb.initDB(defaultStims));

app.ports.saveLog.subscribe(idb.saveLog);
app.ports.saveStim.subscribe(idb.saveStim);
app.ports.saveUser.subscribe(idb.saveUser);

app.ports.fetchFirebaseStims.subscribe(() => firebase.getFirebaseStims());
app.ports.shareStim.subscribe(stim => firebase.addFirebaseStim(stim));
app.ports.changeSkinColour.subscribe(hex => {
  const getSvgDoc = cb => {
    const currentAvatar = document.querySelector('.is-selected')
      .firstElementChild;
    console.log(currentAvatar);
    if (currentAvatar === null) {
      setTimeout(() => getSvgDoc(cb), 300);
    } else {
      const svgDoc = currentAvatar.contentDocument;
      const bodyElements = svgDoc.getElementById('body_change_colour');
      if (bodyElements === null) {
        setTimeout(() => getSvgDoc(cb), 300);
      } else {
        cb();
      }
    }
  };

  const updateSkinColour = () => {
    const currentAvatar = document.querySelector('.is-selected')
      .firstElementChild;
    const svgDoc = currentAvatar.contentDocument;

    const skinColours = svgDoc.getElementById('body_change_colour');
    skinColours.setAttribute('fill', hex);
    console.log('skin colours', hex);
  };
  getSvgDoc(updateSkinColour);
});
