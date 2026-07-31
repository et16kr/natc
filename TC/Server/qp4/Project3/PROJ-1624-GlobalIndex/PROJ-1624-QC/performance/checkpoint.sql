alter system set CHECKPOINT_INTERVAL_IN_SEC = 600000;
alter system set CHECKPOINT_INTERVAL_IN_LOG = 100000;
alter system checkpoint;
