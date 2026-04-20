const mqtt   = require('mqtt');
const logger = require('../utils/logger');
const { ingestSensorData } = require('./iotService');

let client;

function initMqtt() {
  const brokerUrl = process.env.MQTT_BROKER_URL;
  if (!brokerUrl) {
    logger.warn('MQTT_BROKER_URL not set — MQTT service disabled');
    return;
  }

  const options = {
    clientId:  `fleet-server-${Date.now()}`,
    clean:     true,
    reconnectPeriod: 5000,
  };
  if (process.env.MQTT_USERNAME) options.username = process.env.MQTT_USERNAME;
  if (process.env.MQTT_PASSWORD) options.password = process.env.MQTT_PASSWORD;

  client = mqtt.connect(brokerUrl, options);

  client.on('connect', () => {
    const topic = `${process.env.MQTT_TOPIC_PREFIX || 'fleet/trucks'}/+/data`;
    client.subscribe(topic, { qos: 1 }, (err) => {
      if (err) return logger.error('MQTT subscribe error:', err.message);
      logger.info(`✅ MQTT connected and subscribed to: ${topic}`);
    });
  });

  client.on('message', async (topic, message) => {
    try {
      const payload = JSON.parse(message.toString());
      logger.debug(`MQTT message on ${topic}:`, payload);
      await ingestSensorData(payload);
    } catch (err) {
      logger.error('MQTT message processing error:', err.message);
    }
  });

  client.on('error',      (err) => logger.error('MQTT error:', err.message));
  client.on('reconnect',  ()    => logger.warn('MQTT reconnecting...'));
  client.on('disconnect', ()    => logger.warn('MQTT disconnected'));
}

function publishCommand(truckId, command) {
  if (!client?.connected) return false;
  const topic   = `${process.env.MQTT_TOPIC_PREFIX || 'fleet/trucks'}/${truckId}/command`;
  const payload = JSON.stringify({ ...command, timestamp: new Date().toISOString() });
  client.publish(topic, payload, { qos: 1 });
  return true;
}

module.exports = { initMqtt, publishCommand };
