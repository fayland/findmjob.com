<?php
/**
 * !! IMPORTANT !!
 * This is just an example, it not well-formed library
 * We do not recommend use it in production enviroment, use it only with
 * an example code
 * THE BEST WAY TO USE OAUTH IS TO USE OFFICIAL OAUTH LIBRARIES
 *
 * oDesk auth library for using with public API by OAuth (SIMPLE EXAMPLE)
 *
 * @final
 * @package     APIEngine
 * @version     2.2
 * @since       10/19/2010
 * @copyright   Copyright 2010(c) oDesk.com
 * @author      Maksym Novozhylov <mnovozhilov@odesk.com>
 * @license     oDesk's API Terms of Use {@link http://developers.odesk.com/API-Terms-of-Use}
 */
final class oDeskAPI {

    const URL_LOGIN     = 'https://www.odesk.com/login';
    const URL_AUTH      = 'https://www.odesk.com/services/api/auth';
    const URL_ATOKEN    = 'https://www.odesk.com/api/auth/v1/oauth/token/access';
    const URL_RTOKEN    = 'https://www.odesk.com/api/auth/v1/oauth/token/request';
    const COOKIE_TOKEN  = 'odesk_api_oauth_token';

    static
    public $api_key     = null, // consumer key
           $secret      = null, // consumer secret
           $ot_token    = null, // oauth_token, shared request token
           $ot_secret   = null; // oauth_token_secret

    static
    private $api_token  = null,
            $api_secret = null,
            $callback   = null,
            $mode       = 'web',
            $amode      = 'base', // authz mode, base|headers
            $epoint     = 'api', // entry point, equal to BASEURL_TYPE
            $verify_ssl = FALSE, // option
            $cookie_file= './cookie.txt', // option
            $sig_method = 'HMAC-SHA1',
            $proxy      = null, // option
            $proxy_pwd  = null, // option
            $skip_realm = false, // skip realm directive in header auth
            $v_quote    = false, // quote values in header auth
            $debug      = false;

    /**
     * __construct
     *
     * @param   string  $secret     Secret key
     * @param   string  $api_key    Application key
     * @access  public
     */
    function __construct($secret, $api_key) {
        if (!$secret)
            throw new Exception('You must define "secret key".');
        else
            self::$secret = (string) $secret;

        if (!$api_key)
            throw new Exception('You must define "application key".');
        else
            self::$api_key = (string) $api_key;
    }

    /**
     * Set option
     *
     * @param   string  $option Option name
     * @param   mixed   $value  Option value
     * @access  public
     * @return  boolean
     */
    public static function option($option, $value) {
        $r = new ReflectionClass('\\'.__CLASS__);
        try {
            $r->getProperty($option);
            self::$$option = $value;
            return TRUE;
        } catch (ReflectionException $e) {
            return FALSE;
        }
    }

    /**
     * Auth process
     *
     * @param   string  $user   Auth user, for nonweb apps
     * @param   string  $pass   Auth pass, for nonweb apps
     * @access  public
     * @return  string
     */
    public function auth($user = null, $pass = null) {
        $oauth_verifier = (isset($_GET['oauth_verifier']) && !empty($_GET['oauth_verifier']))
                        ? $_GET['oauth_verifier']
                        : null;

        if (isset($_COOKIE[self::COOKIE_TOKEN]) && !empty($_COOKIE[self::COOKIE_TOKEN]))
            self::$api_token = $_COOKIE[self::COOKIE_TOKEN];


        if (self::$api_token == null && $oauth_verifier == null) {
            //{{{ get request token
            $params = self::get_params_for_request();
            ksort($params);
            $api_sig = self::calc_api_sig(null, $params, self::URL_RTOKEN);

            $url = self::URL_RTOKEN . self::merge_params_to_uri(self::get_api_uri($api_sig), $params);

            $data = self::send_request($url, 'post');
            preg_match('~oauth_callback_confirmed=true&oauth_token=([\da-f]{32})&oauth_token_secret=([\da-f]{16})~', $data['response'], $match);
            self::$ot_token  = $match[1];
            self::$ot_secret = $match[2];
            //}}}

            if (self::$mode === 'web') {
                // authorize web application via browser
                header('Location: ' . self::URL_AUTH . '?oauth_token=' . self::$ot_token);
            } else if (self::$mode === 'nonweb') {
                // authorize nonweb application
                // 2. login
                self::send_request(self::URL_LOGIN . self::merge_params_to_uri(null, array('login' => $user, 'password' => $pass, 'action' => 'login'), FALSE), 'post');

                // 3. authorize
                $data = self::send_request(self::URL_AUTH . self::merge_params_to_uri('?oauth_token='.self::$ot_token, array('do' => 'agree')), 'post');
                preg_match('~oauth_verifier=([\da-f]{32})~', $data['response'], $match);
                $verifier = $match[1];

                // 4. get access token
                self::get_api_token($verifier);
            }
        } else if (self::$api_token == null && $oauth_verifier != null) {
            // get api token by access token
            self::get_api_token($oauth_verifier);
            setcookie(self::COOKIE_TOKEN, self::$api_token, time()+3600); // save for 1 hour
        } else {
            // api_token isset
        }

        return array('token' => self::$api_token, 'secret' => self::$api_secret);
    }

    /**
     * Do GET request
     *
     * @param   string      $url    API URL
     * @param   array|null  $params Additional parameters
     * @access  public
     * @return  mixed
     */
    public function get_request($url, $params = array()) {
        return self::request('get', $url, $params);
    }

    /**
     * Do POST request
     *
     * @param   string      $url    API URL
     * @param   array|null  $params Additional parameters
     * @access  public
     * @return  mixed
     */
    public function post_request($url, $params = array()) {
        return self::request('post', $url, $params);
    }

    /**
     * Do PUT request
     *
     * @param   string      $url    API URL
     * @param   array|null  $params Additional parameters
     * @access  public
     * @return  mixed
     */
    public function put_request($url, $params = array()) {
        return self::request('put', $url, $params);
    }

    /**
     * Do DELETE request
     *
     * @param   string      $url    API URL
     * @param   array|null  $params Additional parameters
     * @access  public
     * @return  mixed
     */
    public function delete_request($url, $params = array()) {
        return self::request('delete', $url, $params);
    }

    /**
     * Do request
     *
     * @param   string  $type   Type of request
     * @param   string  $url    URL
     * @param   array   $params Parameters
     * @static
     * @access  public
     * @return  mixed
     */
    static public function request($type, $url, $params = array()) {
        $method = 'POST';
        switch ($type) {
            case 'put':
                $params['http_method'] = 'put';
                break;
            case 'delete':
                $params['http_method'] = 'delete';
                break;
            case 'get':
                $method = 'GET';
                break;
        }

        $_params = self::get_params_for_request();
        $_params += array('oauth_token' => self::$api_token);
        $_p = $_params; // save them for url
        if (sizeof($params) > 0) {
            $_p += $params;
            $_params += self::prepare_params($params);
        }

        ksort($_params);
        ksort($_p);

        $api_sig = self::calc_api_sig(self::$api_secret, self::transcode_params($_params), $url, $method, false);
        $url = $url . self::_merge_params_to_uri(self::get_api_uri($api_sig), $_p, ((self::$epoint == 'gds') ? true : false));

        $data = self::send_request($url, $type);
        if ($data['error'] && !empty($data['error'])) {
            throw new Exception('Can not execute request due to error: '.$data['error']);
        } else if (!isset($data['info']['http_code'])) {
            $d = print_r($data, true);
            throw new Exception('API does not return anything or request could not be finished. Response: '.(empty($t) ? '&lt;EMPTY&gt;' : $t));
        } else if ($data['info']['http_code'] != 200) {
            return $data['response']; // return non200 response, to be able test non-200 reply in public apis
            //throw new Exception('API return code - '.$data['info']['http_code'].'. Can not create '.strtoupper($type).' request.');
        } else {
            return $data['response'];
        }
    }

    /**
     * Return API's URI with signature and key
     *
     * @param   string  $api_sig    Signature
     * @static
     * @access  private
     * @return  string
     */
    static private function get_api_uri($api_sig) {
        return '?oauth_signature=' . urlencode($api_sig);
    }

    static private function get_params_for_request() {
        $p = array(
                'oauth_consumer_key'    => self::$api_key,
                'oauth_signature_method'=> self::$sig_method,
                'oauth_timestamp'       => time(),
                'oauth_nonce'           => substr(md5(microtime(true)), 5)
                );
        if (self::$callback)
            $p += array('oauth_callback' => self::$callback);

        return $p;
    }

    /**
     * Return auth token
     *
     * @param   string  $oauth_verifier Access token
     * @static
     * @access  private
     * @return  mixed
     */
    static private function get_api_token($oauth_verifier = null) {
        if (self::$api_token)
            return self::$api_token;

        if ($oauth_verifier === null)
            $this->auth();

        $params = self::get_params_for_request();
        $params += array(
                    'oauth_verifier'=> $oauth_verifier,
                    'oauth_token'   => self::$ot_token
                );

        ksort($params);
        $api_sig = self::calc_api_sig(self::$ot_secret, $params, self::URL_ATOKEN);

        $url = self::URL_ATOKEN . self::merge_params_to_uri(self::get_api_uri($api_sig), $params);

        $data = self::send_request($url, 'post');
        preg_match('~oauth_token=([\da-f]{32})&oauth_token_secret=([\da-f]{16})~', $data['response'], $match);
        if (!isset($data['info']['http_code'])) {
            throw new Exception('API does not return anything or request could not be finished.');
        } else if ($data['info']['http_code'] != 200) {
            throw new Exception('API return code - '.$data['info']['http_code'].'. Can not get token.');
        } else {
            self::$api_token  = $match[1];
            self::$api_secret = $match[2];
            return self::$api_token;
        }
    }

    /**
     * Send request via CURL
     *
     * @param   string  $url    URL to request
     * @param   string  $type   Type of request
     * @static
     * @access  private
     * @return  array
     */
    static private function send_request($url, $type = 'get') {
        $ch = curl_init();
        if ($type != 'get')
            list($url, $pdata) = explode('?', $url, 2);

        // curl_setopt($ch, CURLOPT_VERBOSE, true);
        curl_setopt($ch, CURLOPT_HEADER, 0);
        if (self::$mode != 'web') {
            $headers[] = 'Connection: Keep-Alive';
            $headers[] = 'Content-type: application/x-www-form-urlencoded;charset=UTF-8';
            if (self::$amode == 'headers' && !is_int(strpos($url, self::URL_LOGIN)) && !is_int(strpos($url, self::URL_AUTH))) {
                if ($type == 'get') {
                    list($url, $pdata) = explode('?', $url, 2);
                } else {
                    $headers[]='Content-Length: 0'; // setup Content-Length by default according to RFC 2616, section 4.4, this is required for oAuth by headers
                }
                $list = explode('&', $pdata);
                if (self::$v_quote) {
                    array_walk($list, function(&$value, $index) {
                        list($k, $v) = explode('=', $value, 2);
                        $value = $k.'="'.$v.'"';
                    });
                }
                $headers[] = 'Authorization: OAuth '.(!self::$skip_realm ? 'realm="oDesk Oauth Library", ' : '').implode(', ', $list);
            }
            curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
            curl_setopt($ch, CURLOPT_ENCODING , 'gzip');
            if (is_int(strpos($url, self::URL_LOGIN)) || is_int(strpos($url, self::URL_AUTH))) {
                // setup cookie for console pages only
                self::set_cookie_file(self::$cookie_file);
                curl_setopt($ch, CURLOPT_COOKIEFILE, self::$cookie_file);
                curl_setopt($ch, CURLOPT_COOKIEJAR, self::$cookie_file);
            }
        }
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_USERAGENT, 'PHP oDeskAPIOAuth library client/1.0');
        if (preg_match('/^https:\/\//', $url) && !self::$verify_ssl) {
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE); //do not verify crt, if selfsigned
        }
        if ($type != 'get') {
            curl_setopt($ch, CURLOPT_POST, true);
            if (self::$amode == 'base' || is_int(strpos($url, self::URL_LOGIN)) || is_int(strpos($url, self::URL_AUTH)))
                curl_setopt($ch, CURLOPT_POSTFIELDS, $pdata);
            curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
        }
        if (self::$proxy) {
            curl_setopt($ch, CURLOPT_HTTPPROXYTUNNEL, 1);
            curl_setopt($ch, CURLOPT_PROXY, self::$proxy);
        }
        if (self::$proxy_pwd) {
            curl_setopt($ch, CURLOPT_PROXYUSERPWD, self::$proxy_pwd);
        }
        curl_setopt($ch, CURLOPT_URL, $url);
        !self::$debug || curl_setopt($ch, CURLINFO_HEADER_OUT, true); //debug
        $response = curl_exec($ch);
        !self::$debug || print(curl_getinfo($ch, CURLINFO_HEADER_OUT)); //debug
        !self::$debug || print_r($response);
        $data['response']= $response;
        $data['info']    = curl_getinfo($ch);
        $data['error']   = curl_error($ch);

        $header_size    = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
        $data['header'] = substr($response, 0, $header_size);
        $data['body']   = substr($response, $header_size);
        curl_close($ch);

        return $data;
    }

    private static function set_cookie_file($cookie_file) {
        if (!file_exists($cookie_file)) {
            if (!($fh = fopen($cookie_file, 'w')))
                throw new Exception('Can not create cookie file, possible not enough permissions.');
            fclose($fh);
        }
    }

    /**
     * Merge parameters to URI (non basic way)
     *
     * @param   string  $uri        URI
     * @param   array   $params     Parameters
     * @param   boolean $encode     Whether to encode url params
     * @static
     * @access  private
     * @return  string
     */
    static private function _merge_params_to_uri($uri, $params, $encode = true, $skip_ss = false) {
        if ($skip_ss) {
            $uri = '';
        } else {
            $uri = ($uri) ? $uri . '&' : '?';
        }

        foreach($params as $k=>$v) {
            if (is_array($v)) {
                foreach ($v as $_k=>$_v) {
                    $uri .= $k.'['.$_k.']='.(($encode) ? urlencode($_v) : $_v).'&';
                }
            } else {
                $uri .= $k.'='.(($encode) ? urlencode($v) : $v).'&';
            }
        }

        return substr($uri, 0, -1);
    }

    /**
     * Basic way
     */
    static private function merge_params_to_uri($uri, $params, $encode=true){
        $uri = ($uri) ? $uri . '&' : '?';
        $uri .= http_build_query($params);
        return $uri;
    }

    /**
     * Normalize requested params, sort in alphabetical order
     *
     * @param   array   $params Array of requested params
     * @static
     * @access  public
     * @return  void
     */
    static private function normalize_params($params) {
        $_params = array();

        ksort($params);
        unset($params['oauth_signature']); // we don't need it here

        foreach ($params as $k => &$v) {
            if (is_array($v)) {
                sort($v);
                foreach ($v as $_v) {
                    $_params[] = $k.'='.rawurlencode($_v);
                }
            } else {
                $_params[] = $k.'='.rawurlencode($v);
            }
        }
        return $_params;
    }

    /**
     * Follow RFC 3986 for all params, transcode them if needed
     *
     * @param   array   $params Params
     * @return  array
     */
    static private function transcode_params($params) {
        $_params = array();

        foreach ($params as $k => $v) {
            if (is_array($v)) {
                $_params[self::transcode($k)] = array_map(array(self,'transcode'), $v);
            } else {
                $_params[self::transcode($k)] = self::transcode($v);
            }
        }

        return $_params;
    }

    protected function transcode($data) {
        return ($data === false)
                ? $data
                : self::encode(rawurldecode($data));
    }

    static private function encode($data) {
        return ($data === false)
                ? $data
                : str_replace('%7E', '~', rawurlencode($data));
    }

    /**
     * Prepare multidimensional params
     *
     * @param   array   $params Params
     * @return  array
     * @static
     * @access  private
     */
    static private function prepare_params($params) {
        $_params = array();

        foreach($params as $k=>$v) {
            $enc_k = self::encode($k);
            if (is_array($v)) {
                foreach ($v as $_k=>$_v) {
                    $_params[$enc_k.'['.self::encode($_k).']'] = self::encode($_v);
                }
            } else {
                $_params[$enc_k] = self::encode($v);
            }
        }

        return $_params;
    }

    /**
     * Calculate API signature for public API
     *
     * @param   string  $token_secret   Secret key
     * @param   array   $params         Array of requested params
     * @param   string  $url            Base URL to
     * @param   string  $method         HTTP method (real)
     * @static
     * @access  public
     * @return  string
     */
    static private function calc_api_sig($token_secret, $params, $url, $method = 'POST', $enc = true) {
        $secret_key  = self::$secret . '&' . $token_secret;
        // multidimensional will be called thru _merge_params_to_uri, which will not do additional encoding, follow RFC3986
        $base_string = $method . '&' . rawurlencode($url) . '&' . ($enc ? rawurlencode(http_build_query($params)) : rawurlencode(self::_merge_params_to_uri('', $params, false, true)));

        return base64_encode(hash_hmac('sha1', $base_string, $secret_key, true));
    }
}

?>
