import { useSiteSuspense } from "@/features/subsite/api/get-site";
import { Image } from "react-bootstrap";

const containerStyles: React.CSSProperties = {
  position: 'relative',
  textAlign: 'center',
  marginBottom: '0.5em',
}

const floatingTextStyles: React.CSSProperties = {
  position: 'absolute',
  top: '90%',
  left: '50%',
  transform: 'translate(-50%,-50%)',
  backgroundColor: '#c3c3c3',
  paddingLeft: '0.5em',
  paddingRight: '0.5em',
};

const ImageUploadPreview = ({ slug, type }: { slug: string; type: 'banner' | 'watermark'}) => {
  const site = useSiteSuspense(slug);
  const hasUpload = type === 'banner' ? site.hasBannerImage : site.hasWatermarkImage;
  const imgUrl = type === 'banner' ? site.bannerImageUrl : site.watermarkImageUrl;

  if (hasUpload) return (
    <div className="checkered-bg" style={containerStyles}>
      <a href={imgUrl} target="_blank" download={`${slug}-signature-${type}`} rel="noreferrer">
        <Image src={imgUrl} style={{height: '175px'}} rounded />
        <span style={floatingTextStyles}>Download this image</span>
      </a>
    </div>
  )
  // default:
  return (
    <div className={`d-flex flex-column my-4 text-align-center }`}>
      <Image src={imgUrl} className={`w-25 ${type === 'watermark' && 'bg-secondary p-3'}`} style={{ minWidth: '275px'}} rounded />
    </div>
  )
}

export default ImageUploadPreview;