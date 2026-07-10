<?php

/*
 * OIDplus 2.0
 * Copyright 2019 - 2023 Daniel Marschall, ViaThinkSoft
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

namespace ViaThinkSoft\OIDplus\Core;

use ViaThinkSoft\OIDplus\Plugins\ObjectTypes\OID\WeidOidConverter;
use ViaThinkSoft\OIDplus\Plugins\PublicPages\Objects\OIDplusPagePublicObjects;

// phpcs:disable PSR1.Files.SideEffects
\defined('INSIDE_OIDPLUS') or die;
// phpcs:enable PSR1.Files.SideEffects

class OIDplusMenuUtils extends OIDplusBaseClass {

	/**
	 * @return string
	 * @throws OIDplusConfigInitializationException
	 * @throws OIDplusException
	 */
	public function nonjs_menu(): string {
		$json = array();

		$static_node_id = $_REQUEST['goto'] ?? 'oidplus:system';

		foreach (OIDplus::getPagePlugins() as $plugin) {
			// Note: The system (OIDplusMenuUtils) does only show the menu of
			//       publicPage plugins. Menu entries for RAs and Admins are
			//       handled by the tree() function of the plugin publicPages/090_login
			if (is_subclass_of($plugin, OIDplusPagePluginPublic::class)) {
				$plugin->tree($json, null, true, $static_node_id);
			}
		}

		$out = '';
		foreach ($json as $x) {
			if ($static_node_id == $x['id']) $out .= '<b>';
			if (isset($x['indent'])) $out .= str_repeat('&nbsp;', $x['indent']*5);
			$cur_lang = OIDplus::getCurrentLang();
			if ($cur_lang != OIDplus::getDefaultLang()) {
				$out .= '<a href="?lang='.$cur_lang.'&amp;goto='.urlencode($x['id']).'">';
			} else {
				$out .= '<a href="?goto='.urlencode($x['id']).'">';
			}
			if (!empty($x['icon'])) $out .= '<img src="'.$x['icon'].'" alt=""> ';
			$out .= htmlentities($x['id']).' | '.htmlentities($x['text']).'</a><br>';
			if ($static_node_id == $x['id']) $out .= '</b>';
		}
		return $out;
	}

	/**
	 * @param string $req_id comes from jsTree via AJAX
	 * @param string $req_goto comes from the user (GET argument)
	 * @return string[]
	 */
	public function json_tree(string $req_id, string $req_goto): array {
		$json = array();

		if ($req_id === '#') {
			foreach (OIDplus::getPagePlugins() as $plugin) {
				// Note: The system (OIDplusMenuUtils) does only show the menu of
				//       publicPage plugins. Menu entries for RAs and Admins are
				//       handled by the tree() function of the plugin publicPages/090_login
				if (is_subclass_of($plugin, OIDplusPagePluginPublic::class)) {
					$plugin->tree($json, null, false, $req_goto);
				}
			}
		} else {
			$json = $this->tree_populate($req_id);
		}

		$this->addHrefIfRequired($json);

		return $json;
	}

	/**
	 * @param array $json
	 * @return void
	 */
	protected function addHrefIfRequired(array &$json): void {
		foreach ($json as &$item) {
			if (isset($item['id'])) {
				if (!isset($item['conditionalselect']) || ($item['conditionalselect'] != 'false')) {
					if (!isset($item['a_attr'])) {
						$item['a_attr'] = array("href" => "?goto=".urlencode($item['id']));
					} else if (!isset($item['a_attr']['href'])) {
						$item['a_attr']['href'] = "?goto=".urlencode($item['id']);
					}
				}
			}

			if (isset($item['children'])) {
				if (is_array($item['children'])) $this->addHrefIfRequired($item['children']);
			}
		}
		unset($item);
	}

	/**
	 * @param string $parent
	 * @param array|true|null $goto_path array [X,Y,Z] to open node X,Y,Z. true to open everything, null to open nothing.
	 * @return array
	 * @throws OIDplusConfigInitializationException
	 * @throws OIDplusException
	 */
	public function tree_populate(string $parent, /*array|true|null*/ $goto_path=null): array {

		$was_weid = str_starts_with(strtolower($parent), 'weid:');
		if ($was_weid && class_exists(WeidOidConverter::class)) {
			$parent = 'oid:'.WeidOidConverter::weid2oid($parent);
		}

		$children = array();

		$parentObj = OIDplusObject::parse($parent);

		if (is_array($goto_path)) array_shift($goto_path);

		$res = OIDplus::db()->query("select * from ###objects where parent = ?", array($parent));
		$res->naturalSortByField('id');
		$max_ent = 0;
		while ($row = $res->fetch_array()) {
			$max_ent++;
			if ($max_ent > 1000) { // TODO: we need to find a solution for this!!!
				// Note: We cannot use id=oidplus:system, otherwise the lazy-load-tree breaks
				$children[] = array('id' => '', 'icon' => '', 'text' => _L('List truncated due to too many subordinate elements'), 'indent' => 0);
				break;
			}

			$obj = OIDplusObject::parse($row['id']);
			if (!$obj) continue; // e.g. object-type plugin disabled

			if (!$obj->userHasReadRights()) continue;

			$child = array();
			if ($was_weid && class_exists(WeidOidConverter::class)) {
				$child['id'] = $row['id'];
				$child['id'] = str_replace('urn:oid:', 'oid:', $child['id']);
				$hf_text = (strtolower($row['id']) == 'oid:') ? 'weid:O-?' : WeidOidConverter::oid2weid(substr($row['id'],strlen('oid:')));
				$hf_text = str_replace('urn:x-weid:', 'weid:', $hf_text);
				// Temporarily prefix a "0." to force class A (O-1-3-6...) because this makes sure there is never an ID conflict in the tree
				$safe_text = (strtolower($row['id']) == 'oid:') ? 'weid:O-?' : WeidOidConverter::oid2weid('0.'.substr($row['id'],strlen('oid:')));
				$safe_text = str_replace('urn:x-weid:O-0-', 'weid:O-', $safe_text);
				$safe_text = substr($safe_text, 0, strlen($safe_text)-2) . '-?';
				$child['id'] = $hf_text . '|' . $safe_text; // Appending "safe text" (Class A WEID) makes sure there is no ID conflict in the tree. oidplus_base.js will strip it away.
			} else {
				$child['id'] = $row['id'];
				$hf_text = $row['id'];
			}

			// Determine display name (relative OID)
			if (!$parentObj) {
				$child['text'] = '';
			} else if ($was_weid && class_exists(WeidOidConverter::class)) {
				if (strtolower($parent) == 'oid:') {
					if (class_exists(OIDplusPagePublicObjects::class) && OIDplusPagePublicObjects::urnViewEnabled()) {
						$child['text'] = substr($hf_text,strlen('weid:')/*remove prefix*/,-2/*remove checksum*/);
					} else {
						$child['text'] = substr($hf_text,0,-2/*remove checksum*/);
					}
				} else {
					$bry = explode('.', $row['id']);
					$last_arc = $bry[count($bry)-1];
					$child['text'] = WeidOidConverter::encodeSingleArc($last_arc);
				}
			} else {
				$child['text'] = $obj->jsTreeNodeName($parentObj);
			}
			$child['text'] .= empty($row['title']) ? /*' -- <i>'.htmlentities('Title missing').'</i>'*/ '' : ' -- <b>' . htmlentities($row['title']) . '</b>';

			// Check if node is confidential, or if one of its parent was confidential
			$is_confidential = $obj->isConfidential();
			if ($is_confidential) {
				$child['text'] = '<font color="gray"><i>'.$child['text'].'</i></font>';
			}

			// Determine icon
			$child['icon'] = $obj->getIcon($row);

			// Check if there are more sub OIDs
			if ($was_weid && class_exists(WeidOidConverter::class)) {
				$tmp = $row['id'];
				$tmp = str_replace('urn:oid:', 'oid:', $tmp);
				$tmp = (strtolower($row['id']) == 'oid:') ? 'weid:O-?' : WeidOidConverter::oid2weid(substr($tmp,strlen('oid:')));
				$tmp = str_replace('urn:x-weid:', 'weid:', $tmp);
			} else {
				$tmp = $row['id'];
			}

			if (($parent == 'urn:') && class_exists(OIDplusPagePublicObjects::class) && OIDplusPagePublicObjects::urnViewEnabled()) {
				// For URNs, open to the 2nd level
				$child['children'] = $this->tree_populate($tmp, $goto_path);
				$child['state'] = array("opened" => true);
			} else if ($goto_path === true) {
				$child['children'] = $this->tree_populate($tmp, $goto_path);
				$child['state'] = array("opened" => true);
			} else if (!is_null($goto_path) && (count($goto_path) > 0) && ($goto_path[0] === $row['id'])) {
				$child['children'] = $this->tree_populate($tmp, $goto_path);
				$child['state'] = array("opened" => true);
			} else {

				// Variant 1: Fast, but does not check for hidden OIDs
				/*
				$obj_children = $obj->getChildren();
				$child['children'] = count($obj_children) > 0;
				*/

				// variant 2
				/*
				$obj_children = $obj->getChildren();
				$child['children'] = false;
				foreach ($obj_children as $obj_test) {
					if (!$obj_test->userHasReadRights()) continue;
					$child['children'] = true;
					break;
				}
				*/

				// variant 3: A bit faster than variant 2
				$child['children'] = false;
				$res2 = OIDplus::db()->query("select id from ###objects where parent = ?", array($obj->nodeId()));
				while ($row2 = $res2->fetch_array()) {
					$obj_test = OIDplusObject::parse($row2['id']);
					if (!$obj_test->userHasReadRights()) continue;
					$child['children'] = true;
					break;
				}

			}

			$children[] = $child;
		}

		return $children;
	}

}
