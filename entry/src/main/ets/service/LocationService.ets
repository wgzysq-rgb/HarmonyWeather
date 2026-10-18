import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, common, Permissions, PermissionRequestResult } from '@kit.AbilityKit';
import { WxCity } from '../model/WeatherModels';

const LOCATION_PERMISSIONS: Permissions[] = ['ohos.permission.APPROXIMATELY_LOCATION'];

/**
 * 定位当前城市：申请近似位置权限 → 取一次坐标 → 逆地理编码成城市名。
 * 任何一步失败都会抛出带中文说明的 Error，由调用方提示并回退到手动搜索。
 */
export async function wxLocateCity(context: common.UIAbilityContext): Promise<WxCity> {
  if (!canIUse('SystemCapability.Location.Location.Core')) {
    throw new Error('当前设备不支持定位，请手动搜索城市');
  }
  const atManager = abilityAccessCtrl.createAtManager();
  const grant: PermissionRequestResult =
    await atManager.requestPermissionsFromUser(context, LOCATION_PERMISSIONS);
  const codes: number[] = grant.authResults;
  if (codes.length === 0 || codes[0] !== 0) {
    throw new Error('未获得定位权限，可手动搜索城市');
  }

  const location: geoLocationManager.Location = await geoLocationManager.getCurrentLocation({
    priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
    scenario: geoLocationManager.LocationRequestScenario.DAILY_LIFE_SERVICE,
    timeoutMs: 10000
  });

  let cityName: string = '当前位置';
  let region: string = '';
  try {
    if (geoLocationManager.isGeocoderAvailable()) {
      const addresses: geoLocationManager.GeoAddress[] = await geoLocationManager.getAddressesFromLocation({
        latitude: location.latitude,
        longitude: location.longitude,
        locale: 'zh'
      });
      if (addresses.length > 0) {
        const address: geoLocationManager.GeoAddress = addresses[0];
        const locality: string = address.locality ?? address.subAdministrativeArea ?? '';
        cityName = locality.length > 0 ? locality : (address.placeName ?? '当前位置');
        region = address.administrativeArea ?? address.countryName ?? '';
      }
    }
  } catch (error) {
    // 逆地理编码不可用时仍可用坐标展示天气
    cityName = '当前位置';
  }

  const id: string = `loc_${location.latitude.toFixed(3)}_${location.longitude.toFixed(3)}`;
  return {
    id: id,
    name: cityName,
    region: region,
    lat: location.latitude,
    lon: location.longitude,
    isLocated: true
  };
}
