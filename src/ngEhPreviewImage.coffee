
app = angular.module 'eHanlin',[]

app.directive 'ngEhPreviewImage', [ '$q', '$timeout', ( $q, $timeout )->

  getImageSize = ( data )->

    deferred = $q.defer()

    $div = $ '<div></div>'
    img = document.createElement 'img'
    $div.append img
    $div.css
      'width':'0px'
      'height':'0px'
      'overflow':'hidden'
      'visibility':'hidden'

    img.onload = ->
      deferred.resolve {size:{width:img.width,height:img.height}, img:img}
      $div.remove()

    img.src = data

    $div.appendTo document.body
    deferred.promise


  getScale = ( oW, oH, w, h )->

    rateW = w / oW
    rateH = h / oH
    if rateW < rateH then rateW else rateH

  resize = ( image, width, height )->
    deferred = $q.defer()
    tmpImg = new Image
    canvas = document.createElement 'canvas'
    canvas.width = width
    canvas.height = height
    ctx = canvas.getContext '2d'
    ctx.drawImage image, 0, 0, width, height
    tmpImg.onload = ->
      deferred.resolve img:tmpImg, size:{width:width,height:height}
    tmpImg.src = canvas.toDataURL 'image/png'
    deferred.promise

  resizeByScale = ( image, width, height )->

    scale = getScale image.width, image.height, width, height
    resize image, scale * image.width, scale * image.height

  scope:
    img:"="

  template:"""
    <div class="ng-eh-preview-image">
      <canvas style="width:100%;"></canvas>
      <i class="fa fa-repeat" ng-click="rotateRight( $event )" ng-mousedown="onPreventDefault( $event )"></i>
    </div>
  """

  link:( scope, element, attrs, ctrl )->

    currentSize = null
    outerCanvas = element.find( 'canvas' )[0]
    clearTimePromise= null
    enabledUpdated = true
    promise = null
    isIos = /(ipad)|(iphone)/i.test navigator.userAgent


    render = ( source, size )->

      outerCanvas.width = w = if size then size.width else source.width
      outerCanvas.height = h = if size then size.height else source.height
      oCtx = outerCanvas.getContext '2d'
      oCtx.drawImage source, 0, 0, w, h

    rotate = ( source )->

      if clearTimePromise
        $timeout.cancel clearTimePromise
        clearTimePromise = null

      canvas = document.createElement 'canvas'
      ctx = canvas.getContext '2d'
      canvas.height = currentSize.width
      canvas.width = currentSize.height
      halfWidth = currentSize.width / 2
      halfHeight = currentSize.height / 2

      ctx.save()
      ctx.translate halfHeight, halfWidth
      ctx.rotate 90 * Math.PI/180
      ctx.drawImage source, -halfWidth, -halfHeight, canvas.height, canvas.width
      ctx.restore()
      [currentSize.width, currentSize.height] = [currentSize.height,currentSize.width]
      clearTimePromise = $timeout ->
        scope.enabledUpdated = false
        scope.img.data = canvas.toDataURL "image/png"
        $timeout -> scope.enabledUpdated = true
      , 750
      render canvas


    scope.$watch 'img', ->

      if enabledUpdated

        promise = getImageSize scope.img.data

        promise.then ( imgDetail )->

          renderImage_ = ( detail )->
            currentSize = if currentSize then currentSize else detail.size
            render detail.img, detail.size

          resizeWidth = 1924

          #fixed ios max size
          if isIos and  (resizeWidth < imgDetail.size.width or resizeWidth < imgDetail.size.height)
            resizePromise = resizeByScale imgDetail.img, resizeWidth, resizeWidth
            resizePromise.then ( resizeDetail )->
              renderImage_ resizeDetail
          else
            renderImage_ imgDetail


    angular.extend scope,

      onPreventDefault:( event )->

        event.preventDefault()

      rotateRight:( event )->
        event.preventDefault()
        promise.then ( detail )->
          rotate outerCanvas

]

