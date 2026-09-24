(function () {
  'use strict';

  var modelPromise = null;
  var blazefaceModel = null;

  function loadScript(src) {
    return new Promise(function (resolve, reject) {
      var existing = document.querySelector('script[data-permuta-src="' + src + '"]');
      if (existing) {
        if (existing.getAttribute('data-loaded') === '1') {
          resolve();
          return;
        }
        existing.addEventListener('load', function () { resolve(); });
        existing.addEventListener('error', reject);
        return;
      }
      var s = document.createElement('script');
      s.src = src;
      s.async = true;
      s.setAttribute('data-permuta-src', src);
      s.onload = function () {
        s.setAttribute('data-loaded', '1');
        resolve();
      };
      s.onerror = reject;
      document.head.appendChild(s);
    });
  }

  function ensureBlazeFace() {
    if (modelPromise) return modelPromise;
    modelPromise = (async function () {
      await loadScript('https://cdn.jsdelivr.net/npm/@tensorflow/tfjs@4.22.0/dist/tf.min.js');
      await loadScript('https://cdn.jsdelivr.net/npm/@tensorflow-models/blazeface@0.1.0/dist/blazeface.min.js');
      if (typeof blazeface === 'undefined' || !blazeface.load) {
        throw new Error('blazeface unavailable');
      }
      blazefaceModel = await blazeface.load();
    })().catch(function () {
      modelPromise = null;
      blazefaceModel = null;
    });
    return modelPromise;
  }

  function loadImage(dataUrl) {
    return new Promise(function (resolve, reject) {
      var img = new Image();
      img.onload = function () { resolve(img); };
      img.onerror = reject;
      img.src = dataUrl;
    });
  }

  /**
   * Heurística: olhos acima da boca = cabeça para cima; olhos abaixo = flip 180°.
   */
  async function detectFlip(dataUrl) {
    try {
      await ensureBlazeFace();
      if (!blazefaceModel) return { needsFlip: false };

      var img = await loadImage(dataUrl);
      var canvas = document.createElement('canvas');
      canvas.width = img.naturalWidth || img.width;
      canvas.height = img.naturalHeight || img.height;
      var ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0);

      var faces = await blazefaceModel.estimateFaces(canvas, false);
      if (!faces || faces.length === 0) return { needsFlip: false };

      var face = faces[0];
      var landmarks = face.landmarks;
      if (!landmarks || landmarks.length < 4) return { needsFlip: false };

      var rightEye = landmarks[0];
      var leftEye = landmarks[1];
      var mouth = landmarks[3];
      var eyeY = (rightEye[1] + leftEye[1]) / 2;
      var mouthY = mouth[1];

      return { needsFlip: eyeY > mouthY };
    } catch (e) {
      return { needsFlip: false };
    }
  }

  window.permutaDocOrientation = {
    detectFlip: detectFlip,
  };
})();
