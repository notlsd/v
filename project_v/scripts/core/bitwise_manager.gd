## BitwiseManager
## 位运算核心模块 - 作为 Autoload 单例运行
## 提供 IP/掩码转换和匹配判定功能
extends Node


## IP 字符串转整数
## 例: "192.168.1.1" -> 3232235777
func ip_to_int(ip_string: String) -> int:
	var parts := ip_string.split(".")
	if parts.size() != 4:
		push_error("Invalid IP format: " + ip_string)
		return 0
	
	var result: int = 0
	for i in range(4):
		var octet := int(parts[i])
		result = result | (octet << (24 - i * 8))
	return result


## 整数转 IP 字符串（用于 UI 显示）
## 例: 3232235777 -> "192.168.1.1"
func int_to_ip(ip_int: int) -> String:
	var octets: Array[int] = []
	for i in range(4):
		octets.append((ip_int >> (24 - i * 8)) & 0xFF)
	return "%d.%d.%d.%d" % octets


## 掩码前缀转整数
## 例: 24 -> 4294967040 (255.255.255.0)
## 例: 16 -> 4294901760 (255.255.0.0)
## 例: 32 -> 4294967295 (255.255.255.255)
func prefix_to_mask(prefix: int) -> int:
	if prefix <= 0:
		return 0
	if prefix >= 32:
		return 0xFFFFFFFF  # 4294967295
	
	# 生成 prefix 个 1，然后左移补 0
	return (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF


## 核心判定：执行位运算 AND 并返回结果
## Result = IP & Mask
func apply_mask(ip: int, mask: int) -> int:
	return ip & mask


## 判定是否匹配目标子网
func check_match(ip: int, mask: int, target_subnet: int) -> bool:
	return apply_mask(ip, mask) == target_subnet


## 生成指定子网内的随机 IP
## 例: generate_random_ip_in_subnet(3232235776, 24) 会生成 192.168.1.x
func generate_random_ip_in_subnet(subnet: int, prefix: int) -> int:
	var host_bits := 32 - prefix
	var max_host := (1 << host_bits) - 1
	var random_host := randi() % max_host + 1  # 避免 0（网络地址）
	return subnet | random_host


## 生成不在指定子网内的随机 IP（用于干扰项）
## 保持在 192.168.x.x 范围内
func generate_random_ip_outside_subnet(subnet: int, prefix: int) -> int:
	var base_ip := ip_to_int("192.168.0.0")
	var attempts := 0
	while attempts < 100:
		var random_ip := base_ip | (randi() % 65536)  # 192.168.0.0 - 192.168.255.255
		if apply_mask(random_ip, prefix_to_mask(prefix)) != subnet:
			return random_ip
		attempts += 1
	# 如果尝试太多次，返回一个明显不同的子网
	return ip_to_int("192.168.0.1")
