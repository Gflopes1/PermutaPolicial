(function () {
  'use strict';

  var cvReadyPromise = null;

  function loadOpenCv() {
    if (typeof cv !== 'undefined' && cv.Mat) {
      return Promise.resolve();
    }
    if (cvReadyPromise) return cvReadyPromise;

    cvReadyPromise = new Promise(function (resolve, reject) {
      var existing = document.querySelector('script[data-permuta-opencv]');
      if (existing && typeof cv !== 'undefined') {
        if (cv.Mat) {
          resolve();
          return;
        }
        cv['onRuntimeInitialized'] = resolve;
        return;
      }
      var s = document.createElement('script');
      s.src = 'https://docs.opencv.org/4.9.0/opencv.js';
      s.async = true;
      s.setAttribute('data-permuta-opencv', '1');
      s.onload = function () {
        if (typeof cv === 'undefined') {
          reject(new Error('opencv not defined'));
          return;
        }
        if (cv.Mat) {
          resolve();
        } else {
          cv['onRuntimeInitialized'] = resolve;
        }
      };
      s.onerror = reject;
      document.head.appendChild(s);
    }).catch(function () {
      cvReadyPromise = null;
    });

    return cvReadyPromise;
  }

  function loadImage(dataUrl) {
    return new Promise(function (resolve, reject) {
      var img = new Image();
      img.onload = function () { resolve(img); };
      img.onerror = reject;
      img.src = dataUrl;
    });
  }

  function canvasToDataUrl(canvas) {
    return canvas.toDataURL('image/jpeg', 0.92);
  }

  function orderQuadPoints(pts) {
    var sorted = pts.slice().sort(function (a, b) { return a.y - b.y; });
    var top = sorted.slice(0, 2).sort(function (a, b) { return a.x - b.x; });
    var bottom = sorted.slice(2, 4).sort(function (a, b) { return a.x - b.x; });
    return [top[0], top[1], bottom[1], bottom[0]];
  }

  function dist(a, b) {
    var dx = a.x - b.x;
    var dy = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * Pipeline clássico document scanner: Canny → maior quadrilátero → warpPerspective.
   * Sem contorno confiável: devolve original (wasCropped: false).
   */
  async function tryCropAndWarp(dataUrl) {
    try {
      await loadOpenCv();
      if (typeof cv === 'undefined' || !cv.Mat) {
        return { dataUrl: dataUrl, wasCropped: false };
      }

      var img = await loadImage(dataUrl);
      var canvas = document.createElement('canvas');
      canvas.width = img.naturalWidth || img.width;
      canvas.height = img.naturalHeight || img.height;
      var ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0);

      var src = cv.imread(canvas);
      var gray = new cv.Mat();
      var blurred = new cv.Mat();
      var edges = new cv.Mat();
      var contours = new cv.MatVector();
      var hierarchy = new cv.Mat();

      try {
        cv.cvtColor(src, gray, cv.COLOR_RGBA2GRAY);
        cv.GaussianBlur(gray, blurred, new cv.Size(5, 5), 0);
        cv.Canny(blurred, edges, 50, 150);

        cv.findContours(edges, contours, hierarchy, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);

        var imgArea = src.rows * src.cols;
        var minArea = imgArea * 0.08;
        var bestQuad = null;
        var bestArea = 0;

        for (var i = 0; i < contours.size(); i++) {
          var cnt = contours.get(i);
          var peri = cv.arcLength(cnt, true);
          var approx = new cv.Mat();
          cv.approxPolyDP(cnt, approx, 0.02 * peri, true);

          if (approx.rows === 4) {
            var area = Math.abs(cv.contourArea(approx));
            if (area > minArea && area > bestArea) {
              var pts = [];
              for (var j = 0; j < 4; j++) {
                pts.push({
                  x: approx.intPtr(j, 0)[0],
                  y: approx.intPtr(j, 0)[1],
                });
              }
              var w1 = dist(pts[0], pts[1]);
              var w2 = dist(pts[2], pts[3]);
              var h1 = dist(pts[0], pts[3]);
              var h2 = dist(pts[1], pts[2]);
              var aspect = Math.max(w1, w2) / Math.max(h1, h2, 1);
              if (aspect > 0.25 && aspect < 4.0) {
                bestArea = area;
                bestQuad = pts;
              }
            }
          }
          approx.delete();
          cnt.delete();
        }

        if (!bestQuad) {
          return { dataUrl: dataUrl, wasCropped: false };
        }

        var ordered = orderQuadPoints(bestQuad);
        var maxWidth = Math.max(
          dist(ordered[0], ordered[1]),
          dist(ordered[2], ordered[3])
        );
        var maxHeight = Math.max(
          dist(ordered[0], ordered[3]),
          dist(ordered[1], ordered[2])
        );

        maxWidth = Math.round(maxWidth);
        maxHeight = Math.round(maxHeight);
        if (maxWidth < 80 || maxHeight < 80) {
          return { dataUrl: dataUrl, wasCropped: false };
        }

        var srcTri = cv.matFromArray(4, 1, cv.CV_32FC2, [
          ordered[0].x, ordered[0].y,
          ordered[1].x, ordered[1].y,
          ordered[2].x, ordered[2].y,
          ordered[3].x, ordered[3].y,
        ]);
        var dstTri = cv.matFromArray(4, 1, cv.CV_32FC2, [
          0, 0,
          maxWidth - 1, 0,
          maxWidth - 1, maxHeight - 1,
          0, maxHeight - 1,
        ]);

        var M = cv.getPerspectiveTransform(srcTri, dstTri);
        var warped = new cv.Mat();
        cv.warpPerspective(src, warped, M, new cv.Size(maxWidth, maxHeight));

        var outCanvas = document.createElement('canvas');
        outCanvas.width = maxWidth;
        outCanvas.height = maxHeight;
        cv.imshow(outCanvas, warped);

        srcTri.delete();
        dstTri.delete();
        M.delete();
        warped.delete();

        return { dataUrl: canvasToDataUrl(outCanvas), wasCropped: true };
      } finally {
        src.delete();
        gray.delete();
        blurred.delete();
        edges.delete();
        contours.delete();
        hierarchy.delete();
      }
    } catch (e) {
      return { dataUrl: dataUrl, wasCropped: false };
    }
  }

  window.permutaDocAutoCrop = {
    tryCropAndWarp: tryCropAndWarp,
  };
})();
