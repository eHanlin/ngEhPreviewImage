
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

        promise.then ( detail )->

          currentSize = if currentSize then currentSize else detail.size
          render detail.img, detail.size

    angular.extend scope,

      onPreventDefault:( event )->

        event.preventDefault()

      rotateRight:( event )->
        event.preventDefault()
        promise.then ( detail )->
          rotate outerCanvas

]

