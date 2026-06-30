import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { AppUtil } from './AppUtil'

export interface PickImageAddr {
  photoUri: string
  cachePath?: string
  cacheFileUri?: string
}

export class GalleryImageUtil {
  static async pickOneImage(): Promise<PickImageAddr> {
    const options = new photoAccessHelper.PhotoSelectOptions()
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
    options.maxSelectNumber = 1

    const picker = new photoAccessHelper.PhotoViewPicker()
    const result = await picker.select(options)
    const photoUri = result.photoUris?.[0] ?? ''

    const ret: PickImageAddr = { photoUri }
    return ret
  }

  static async exportPhotoUriToCache(photoUri: string): Promise<PickImageAddr> {
    if (!photoUri) throw new Error('photoUri is empty')

    const context = AppUtil.abilityContext
    const cachePath = `${context.cacheDir}/picked_${Date.now()}.jpg`
    const src = await fileIo.open(photoUri, fileIo.OpenMode.READ_ONLY)
    const srcImage = image.createImageSource(src.fd)
    const packer = image.createImagePacker()
    const buf = await packer.packing(srcImage, { format: 'image/jpeg', quality: 100 })
    const dst = fileIo.openSync(cachePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC)
    fileIo.writeSync(dst.fd, buf)

    fileIo.closeSync(dst)
    fileIo.closeSync(src)

    const cacheFileUri = fileUri.getUriFromPath(cachePath)

    const ret: PickImageAddr = { photoUri, cachePath, cacheFileUri }
    return ret
  }
}
