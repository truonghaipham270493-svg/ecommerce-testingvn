import config from 'config';

type ConfigStructure = {
  shop: {
    homeUrl: string;
    currency: string;
    language: string;
    timeZone: string;
    weightUnit: string;
  };
  system: {
    extensions: Array<{
      name: string;
      resolve: string;
      enabled: boolean;
    }>;
    notification_emails: {
      from: string;
      reset_password: {
        enabled: boolean;
        templatePath?: string;
      };
      order_confirmation: {
        enabled: boolean;
        templatePath?: string;
      };
      customer_welcome: {
        enabled: boolean;
        templatePath?: string;
      };
    };
    file_storage: string;
  };
  pricing: {
    tax: {
      price_including_tax: boolean;
      rounding: string;
      precision: number;
      round_level: string;
    };
    rounding: string;
    precision: number;
  };
  catalog: {
    collectionPageSize: number;
    product: {
      image: {
        width: number;
        height: number;
      };
    };
    showOutOfStockProduct: boolean;
  };
  themeConfig: {
    logo: {
      alt: string | undefined;
      src: string | undefined;
      width: number | undefined;
      height: number | undefined;
    };
    headTags: {
      links: any[];
      metas: any[];
      scripts: any[];
      bases: any[];
    };
    copyRight: string;
  };
  oms: {
    order: {
      shipmentStatus: Record<
        string,
        {
          name: string;
          badge: string;
          progress: string;
          isDefault?: boolean;
          isCancelable?: boolean;
        }
      >;
      paymentStatus: Record<
        string,
        {
          name: string;
          badge: string;
          progress: string;
          isDefault?: boolean;
          isCancelable?: boolean;
        }
      >;
      status: Record<
        string,
        {
          name: string;
          badge: string;
          progress: string;
          isDefault?: boolean;
          next: string[];
        }
      >;
      psoMapping: Record<string, string>;
      reStockAfterCancellation: boolean;
    };
    carriers: Record<
      string,
      {
        name: string;
        trackingUrl?: string;
      }
    >;
  };
};

type PathValue<T, P extends string> = P extends keyof T
  ? T[P]
  : P extends `${infer K}.${infer Rest}`
  ? K extends keyof T
    ? PathValue<T[K], Rest>
    : never
  : never;

type ConfigPath =
  | keyof ConfigStructure
  | {
      [K in keyof ConfigStructure]: K extends string
        ?
            | `${K}.${Extract<keyof ConfigStructure[K], string>}`
            | {
                [K2 in keyof ConfigStructure[K]]: K2 extends string
                  ?
                      | `${K}.${K2}.${Extract<
                          keyof ConfigStructure[K][K2],
                          string
                        >}`
                      | {
                          [K3 in keyof ConfigStructure[K][K2]]: K3 extends string
                            ? `${K}.${K2}.${K3}.${Extract<
                                keyof ConfigStructure[K][K2][K3],
                                string
                              >}`
                            : never;
                        }[keyof ConfigStructure[K][K2]]
                  : never;
              }[keyof ConfigStructure[K]]
        : never;
    }[keyof ConfigStructure];

/**
 * Get the configuration value base on path. Return the default value if the path is not found.
 */
export function getConfig<P extends ConfigPath>(
  path: P,
  defaultValue?: PathValue<ConfigStructure, P>
): PathValue<ConfigStructure, P> {
  return config.has(path)
    ? config.get<PathValue<ConfigStructure, P>>(path)
    : (defaultValue as PathValue<ConfigStructure, P>);
}
